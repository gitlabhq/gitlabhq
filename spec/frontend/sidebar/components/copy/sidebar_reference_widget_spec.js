import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { TYPE_ISSUE, TYPE_MERGE_REQUEST } from '~/issues/constants';
import SidebarReferenceWidget from '~/sidebar/components/copy/sidebar_reference_widget.vue';
import issueReferenceQuery from '~/sidebar/queries/issue_reference.query.graphql';
import mergeRequestReferenceQuery from '~/sidebar/queries/merge_request_reference.query.graphql';
import CopyableField from '~/sidebar/components/copy/copyable_field.vue';
import { issueReferenceResponse } from '../../mock_data';

describe('Sidebar Reference Widget', () => {
  let wrapper;
  let fakeApollo;

  const mockReferenceValue = 'reference-1234';

  const findCopyableField = () => wrapper.findComponent(CopyableField);

  const createComponent = ({
    issuableType = TYPE_ISSUE,
    referenceQuery = issueReferenceQuery,
    referenceQueryHandler = jest.fn().mockResolvedValue(issueReferenceResponse(mockReferenceValue)),
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

  describe('when reference is loading', () => {
    it('sets CopyableField `is-loading` prop to `true`', () => {
      createComponent({ referenceQueryHandler: jest.fn().mockReturnValue(new Promise(() => {})) });
      expect(findCopyableField().props('isLoading')).toBe(true);
    });
  });

  describe.each([
    [TYPE_ISSUE, issueReferenceQuery],
    [TYPE_MERGE_REQUEST, mergeRequestReferenceQuery],
  ])('when issuableType is %s', (issuableType, referenceQuery) => {
    it('sets CopyableField `value` prop to reference value', async () => {
      createComponent({
        issuableType,
        referenceQuery,
      });

      await waitForPromises();

      expect(findCopyableField().props('value')).toBe(mockReferenceValue);
    });

    describe('when error occurs', () => {
      it(`emits 'fetch-error' event with correct parameters`, async () => {
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
});
