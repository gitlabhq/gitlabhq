import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import { GlDisclosureDropdown } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_MERGE_REQUEST } from '~/graphql_shared/constants';
import StackDropdown from '~/merge_requests/components/stack_dropdown.vue';
import mergeRequestStackQuery from '~/merge_requests/queries/merge_request_stack.query.graphql';

Vue.use(PiniaVuePlugin);
Vue.use(VueApollo);

const MOCK_MR_ID = 1;
const MOCK_MR_GQL_ID = convertToGraphQLId(TYPENAME_MERGE_REQUEST, MOCK_MR_ID);

const createMockStackItem = (id) => ({
  id: convertToGraphQLId(TYPENAME_MERGE_REQUEST, id),
  text: `Merge request ${id}`,
  href: `/group/project/-/merge_requests/${id}`,
  createdAt: '2024-01-01T00:00:00Z',
  diffStatsSummary: {
    fileCount: 1,
    additions: 10,
    deletions: 10,
  },
});

const mockStack = [createMockStackItem(1), createMockStackItem(2), createMockStackItem(3)];

describe('StackDropdown', () => {
  let wrapper;
  let pinia;
  let stackQueryHandler;

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findToggleButton = () => wrapper.find('button');

  const createComponent = ({ mrId = MOCK_MR_ID, stack = mockStack } = {}) => {
    stackQueryHandler = jest.fn().mockResolvedValue({
      data: {
        mergeRequest: {
          id: convertToGraphQLId(TYPENAME_MERGE_REQUEST, mrId),
          stack,
        },
      },
    });

    const apolloProvider = createMockApollo([[mergeRequestStackQuery, stackQueryHandler]]);

    useNotes().noteableData.id = mrId;

    wrapper = mount(StackDropdown, { apolloProvider, pinia, provide: { defaultBranch: 'main' } });
  };

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes();
  });

  it('does not render the dropdown before data loads', () => {
    createComponent();

    expect(findDropdown().exists()).toBe(false);
  });

  describe('when stack is empty', () => {
    beforeEach(async () => {
      createComponent({ stack: [] });
      await waitForPromises();
    });

    it('does not render the dropdown', () => {
      createComponent();

      expect(findDropdown().exists()).toBe(false);
    });
  });

  describe('when stack data is loaded', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders the dropdown', () => {
      expect(findDropdown().exists()).toBe(true);
    });

    it('passes reversed stack items as the items prop', () => {
      expect(findDropdown().props('items')).toEqual(mockStack.toReversed());
    });

    it('queries with the merge request GraphQL ID from the store', () => {
      expect(stackQueryHandler).toHaveBeenCalledWith({ id: MOCK_MR_GQL_ID });
    });
  });

  describe('toggle text', () => {
    it.each`
      mrId | expectedText
      ${1} | ${'1 of 3'}
      ${2} | ${'2 of 3'}
      ${3} | ${'3 of 3'}
    `(
      'shows "$expectedText" when current MR is at position $mrId',
      async ({ mrId, expectedText }) => {
        createComponent({ mrId });
        await waitForPromises();

        expect(findToggleButton().text()).toContain(expectedText);
      },
    );
  });
});
