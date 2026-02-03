import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import MergeChecksTitleRegex from '~/vue_merge_request_widget/components/checks/title_regex.vue';
import MergeChecksMessage from '~/vue_merge_request_widget/components/checks/message.vue';
import titleRegexQuery from '~/vue_merge_request_widget/queries/title_regex.query.graphql';

Vue.use(VueApollo);

const TEST_PROJECT_PATH = 'gitlab-org/gitlab';
const TEST_PROJECT_ID = 'gid://gitlab/Project/1';
const DEFAULT_CHECK = { status: 'FAILED', identifier: 'title_regex' };
const DEFAULT_MR = { targetProjectFullPath: TEST_PROJECT_PATH };

describe('MergeChecksTitleRegex component', () => {
  let wrapper;

  const createTitleRegexQueryResponse = (mergeRequestTitleRegexDescription = null) => ({
    data: {
      project: {
        __typename: 'Project',
        id: TEST_PROJECT_ID,
        mergeRequestTitleRegexDescription,
      },
    },
  });
  const createDefaultTitleRegexQueryHandler = () =>
    jest.fn().mockResolvedValue(createTitleRegexQueryResponse());

  const createComponent = async ({
    check = DEFAULT_CHECK,
    mr = DEFAULT_MR,
    titleRegexQueryHandler = createDefaultTitleRegexQueryHandler(),
  } = {}) => {
    const apolloProvider = createMockApollo([[titleRegexQuery, titleRegexQueryHandler]]);

    wrapper = mountExtended(MergeChecksTitleRegex, {
      apolloProvider,
      propsData: { check, mr },
    });

    await waitForPromises();
  };

  it('passes check to MergeChecksMessage', async () => {
    const check = { status: 'FAILED', identifier: 'title_regex' };
    await createComponent({ check });

    expect(wrapper.findComponent(MergeChecksMessage).props('check')).toEqual(check);
  });

  it('links to the edit page', async () => {
    await createComponent();

    expect(wrapper.findByTestId('extension-actions-button').attributes('href')).toBe(
      `${document.location.pathname.replace(/\/$/, '')}/edit`,
    );
  });

  it('queries for title regex description with correct project path', async () => {
    const titleRegexQueryHandler = jest.fn().mockResolvedValue(createTitleRegexQueryResponse());
    await createComponent({ titleRegexQueryHandler });

    expect(titleRegexQueryHandler).toHaveBeenCalledWith({ projectPath: TEST_PROJECT_PATH });
  });

  it.each`
    scenario                                    | description                                | shouldExist
    ${'renders description when present'}       | ${'MR title must match: ^feat|fix|chore:'} | ${true}
    ${'does not render description when null'}  | ${null}                                    | ${false}
    ${'does not render description when empty'} | ${''}                                      | ${false}
  `('$scenario', async ({ description, shouldExist }) => {
    await createComponent({
      titleRegexQueryHandler: jest
        .fn()
        .mockResolvedValue(createTitleRegexQueryResponse(description)),
    });

    const descriptionEl = wrapper.find('.gl-text-subtle');
    expect(descriptionEl.exists()).toBe(shouldExist);

    if (shouldExist) {
      expect(descriptionEl.text()).toBe(description);
    }
  });
});
