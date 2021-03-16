import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { IssuableType } from '~/issue_show/constants';
import SidebarReferenceWidget from '~/sidebar/components/reference/sidebar_reference_widget.vue';
import issueReferenceQuery from '~/sidebar/queries/issue_reference.query.graphql';
import mergeRequestReferenceQuery from '~/sidebar/queries/merge_request_reference.query.graphql';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { issueReferenceResponse } from '../../mock_data';

describe('Sidebar Reference Widget', () => {
  let wrapper;
  let fakeApollo;
  const referenceText = 'reference';

  const createComponent = ({
    issuableType,
    referenceQuery = issueReferenceQuery,
    referenceQueryHandler = jest.fn().mockResolvedValue(issueReferenceResponse(referenceText)),
  } = {}) => {
    Vue.use(VueApollo);

    fakeApollo = createMockApollo([[referenceQuery, referenceQueryHandler]]);

    wrapper = shallowMount(SidebarReferenceWidget, {
      apolloProvider: fakeApollo,
      provide: {
        fullPath: 'group/project',
        iid: '1',
      },
      propsData: {
        issuableType,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe.each([
    [IssuableType.Issue, issueReferenceQuery],
    [IssuableType.MergeRequest, mergeRequestReferenceQuery],
  ])('when issuableType is %s', (issuableType, referenceQuery) => {
    it('displays the reference text', async () => {
      createComponent({
        issuableType,
        referenceQuery,
      });

      await waitForPromises();

      expect(wrapper.text()).toContain(referenceText);
    });

    it('displays loading icon while fetching and hides clipboard icon', async () => {
      createComponent({
        issuableType,
        referenceQuery,
      });

      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
      expect(wrapper.find(ClipboardButton).exists()).toBe(false);
    });

    it('calls createFlash with correct parameters', async () => {
      const mockError = new Error('mayday');

      createComponent({
        issuableType,
        referenceQuery,
        referenceQueryHandler: jest.fn().mockRejectedValue(mockError),
      });

      await waitForPromises();

      const [
        [
          {
            message,
            error: { networkError },
          },
        ],
      ] = wrapper.emitted('fetch-error');
      expect(message).toBe('An error occurred while fetching reference');
      expect(networkError).toEqual(mockError);
    });
  });
});
