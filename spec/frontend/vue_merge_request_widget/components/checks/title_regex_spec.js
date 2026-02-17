import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlPopover } from '@gitlab/ui';
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

  const createTitleRegexQueryResponse = ({
    mergeRequestTitleRegex = null,
    mergeRequestTitleRegexDescription = null,
  } = {}) => ({
    data: {
      project: {
        __typename: 'Project',
        id: TEST_PROJECT_ID,
        mergeRequestTitleRegex,
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

  describe('popover', () => {
    const findPopover = () => wrapper.findComponent(GlPopover);
    const findHelpButton = () => wrapper.find('#title-regex-help');

    it('renders popover when description is present', async () => {
      await createComponent({
        titleRegexQueryHandler: jest.fn().mockResolvedValue(
          createTitleRegexQueryResponse({
            mergeRequestTitleRegexDescription: 'Use conventional commits',
          }),
        ),
      });

      expect(findPopover().exists()).toBe(true);
      expect(findHelpButton().exists()).toBe(true);
    });

    it('renders popover when regex is present', async () => {
      await createComponent({
        titleRegexQueryHandler: jest.fn().mockResolvedValue(
          createTitleRegexQueryResponse({
            mergeRequestTitleRegex: '^(feat|fix):',
          }),
        ),
      });

      expect(findPopover().exists()).toBe(true);
    });

    it('does not render popover when neither description nor regex is present', async () => {
      await createComponent();

      expect(findPopover().exists()).toBe(false);
      expect(findHelpButton().exists()).toBe(false);
    });

    it('displays description and regex in popover', async () => {
      const description = 'Use conventional commits format';
      const regex = '^(feat|fix|chore):';

      await createComponent({
        titleRegexQueryHandler: jest.fn().mockResolvedValue(
          createTitleRegexQueryResponse({
            mergeRequestTitleRegex: regex,
            mergeRequestTitleRegexDescription: description,
          }),
        ),
      });

      const popover = findPopover();
      expect(popover.text()).toContain(description);
      expect(popover.find('code').text()).toBe(regex);
    });

    it('has correct popover title', async () => {
      await createComponent({
        titleRegexQueryHandler: jest.fn().mockResolvedValue(
          createTitleRegexQueryResponse({
            mergeRequestTitleRegexDescription: 'Some description',
          }),
        ),
      });

      expect(findPopover().props('title')).toBe('Naming convention');
    });
  });
});
