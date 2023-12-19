import { GlAlert, GlFormInput, GlForm, GlLink } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BoardEditableItem from '~/boards/components/sidebar/board_editable_item.vue';
import BoardSidebarTitle from '~/boards/components/sidebar/board_sidebar_title.vue';
import issueSetTitleMutation from '~/boards/graphql/issue_set_title.mutation.graphql';
import * as cacheUpdates from '~/boards/graphql/cache_updates';
import updateEpicTitleMutation from '~/sidebar/queries/update_epic_title.mutation.graphql';
import { updateIssueTitleResponse, updateEpicTitleResponse } from '../../mock_data';

Vue.use(VueApollo);

const TEST_TITLE = 'New item title';
const TEST_ISSUE_A = {
  id: 'gid://gitlab/Issue/1',
  iid: 8,
  title: 'Issue 1',
  referencePath: 'h/b#1',
  webUrl: 'webUrl',
};
const TEST_ISSUE_B = {
  id: 'gid://gitlab/Issue/2',
  iid: 9,
  title: 'Issue 2',
  referencePath: 'h/b#2',
  webUrl: 'webUrl',
};

describe('BoardSidebarTitle', () => {
  let wrapper;
  let mockApollo;

  const issueSetTitleMutationHandlerSuccess = jest.fn().mockResolvedValue(updateIssueTitleResponse);
  const issueSetTitleMutationHandlerFailure = jest.fn().mockRejectedValue(new Error('error'));
  const updateEpicTitleMutationHandlerSuccess = jest
    .fn()
    .mockResolvedValue(updateEpicTitleResponse);

  beforeEach(() => {
    cacheUpdates.setError = jest.fn();
  });

  afterEach(() => {
    localStorage.clear();
  });

  const createWrapper = ({
    item = TEST_ISSUE_A,
    provide = {},
    issueSetTitleMutationHandler = issueSetTitleMutationHandlerSuccess,
  } = {}) => {
    mockApollo = createMockApollo([
      [issueSetTitleMutation, issueSetTitleMutationHandler],
      [updateEpicTitleMutation, updateEpicTitleMutationHandlerSuccess],
    ]);

    wrapper = shallowMountExtended(BoardSidebarTitle, {
      apolloProvider: mockApollo,
      provide: {
        canUpdate: true,
        fullPath: 'gitlab-org',
        issuableType: 'issue',
        isEpicBoard: false,
        ...provide,
      },
      propsData: {
        activeItem: item,
      },
      stubs: {
        'board-editable-item': BoardEditableItem,
      },
    });
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findFormInput = () => wrapper.findComponent(GlFormInput);
  const findGlLink = () => wrapper.findComponent(GlLink);
  const findEditableItem = () => wrapper.findComponent(BoardEditableItem);
  const findCancelButton = () => wrapper.findByTestId('cancel-button');
  const findTitle = () => wrapper.findByTestId('item-title');
  const findCollapsed = () => wrapper.findByTestId('collapsed-content');

  it('renders title and reference', () => {
    createWrapper();

    expect(findTitle().text()).toContain(TEST_ISSUE_A.title);
    expect(findCollapsed().text()).toContain(TEST_ISSUE_A.referencePath);
  });

  it('does not render alert', () => {
    createWrapper();

    expect(findAlert().exists()).toBe(false);
  });

  it('links title to the corresponding issue', () => {
    createWrapper();

    expect(findGlLink().attributes('href')).toBe('webUrl');
  });

  describe('when new title is submitted', () => {
    beforeEach(async () => {
      createWrapper();

      findFormInput().vm.$emit('input', TEST_TITLE);
      findForm().vm.$emit('submit', { preventDefault: () => {} });
      await nextTick();
    });

    it('collapses sidebar and renders new title', async () => {
      await waitForPromises();
      expect(findCollapsed().isVisible()).toBe(true);
    });

    it('renders correct title', async () => {
      createWrapper({ item: { ...TEST_ISSUE_A, title: TEST_TITLE } });
      await waitForPromises();

      expect(findTitle().text()).toContain(TEST_TITLE);
    });
  });

  it.each`
    issuableType | isEpicBoard | queryHandler                             | notCalledHandler
    ${'issue'}   | ${false}    | ${issueSetTitleMutationHandlerSuccess}   | ${updateEpicTitleMutationHandlerSuccess}
    ${'epic'}    | ${true}     | ${updateEpicTitleMutationHandlerSuccess} | ${issueSetTitleMutationHandlerSuccess}
  `(
    'updates $issuableType title',
    async ({ issuableType, isEpicBoard, queryHandler, notCalledHandler }) => {
      createWrapper({
        provide: {
          issuableType,
          isEpicBoard,
        },
      });

      await nextTick();

      findFormInput().vm.$emit('input', TEST_TITLE);
      findForm().vm.$emit('submit', { preventDefault: () => {} });
      await nextTick();

      expect(queryHandler).toHaveBeenCalled();
      expect(notCalledHandler).not.toHaveBeenCalled();
    },
  );

  describe('when submitting and invalid title', () => {
    beforeEach(async () => {
      createWrapper();

      findFormInput().vm.$emit('input', '');
      findForm().vm.$emit('submit', { preventDefault: () => {} });
      await nextTick();
    });

    it('does not update title', () => {
      expect(issueSetTitleMutationHandlerSuccess).not.toHaveBeenCalled();
    });
  });

  describe('when abandoning the form without saving', () => {
    beforeEach(async () => {
      createWrapper();

      wrapper.vm.$refs.sidebarItem.expand();
      findFormInput().vm.$emit('input', TEST_TITLE);
      findEditableItem().vm.$emit('off-click');
      await nextTick();
    });

    it('does not collapses sidebar and shows alert', () => {
      expect(findCollapsed().isVisible()).toBe(false);
      expect(findAlert().exists()).toBe(true);
      expect(localStorage.getItem(`${TEST_ISSUE_A.id}/item-title-pending-changes`)).toBe(
        TEST_TITLE,
      );
    });
  });

  describe('when accessing the form with pending changes', () => {
    beforeAll(() => {
      localStorage.setItem(`${TEST_ISSUE_A.id}/item-title-pending-changes`, TEST_TITLE);

      createWrapper();
    });

    it('sets title, expands item and shows alert', () => {
      expect(findFormInput().attributes('value')).toBe(TEST_TITLE);
      expect(findCollapsed().isVisible()).toBe(false);
      expect(findAlert().exists()).toBe(true);
    });
  });

  describe('when cancel button is clicked', () => {
    beforeEach(async () => {
      createWrapper({ item: TEST_ISSUE_B });

      findFormInput().vm.$emit('input', TEST_TITLE);
      findCancelButton().vm.$emit('click');
      await nextTick();
    });

    it('collapses sidebar and render former title', () => {
      expect(issueSetTitleMutationHandlerSuccess).not.toHaveBeenCalled();
      expect(findCollapsed().isVisible()).toBe(true);
      expect(findTitle().text()).toBe(TEST_ISSUE_B.title);
    });
  });

  describe('when the mutation fails', () => {
    beforeEach(async () => {
      createWrapper({
        item: TEST_ISSUE_B,
        issueSetTitleMutationHandler: issueSetTitleMutationHandlerFailure,
      });

      findFormInput().vm.$emit('input', 'Invalid title');
      findForm().vm.$emit('submit', { preventDefault: () => {} });
      await nextTick();
    });

    it('collapses sidebar and renders former item title', async () => {
      expect(findCollapsed().isVisible()).toBe(true);
      expect(findTitle().text()).toContain(TEST_ISSUE_B.title);
      await waitForPromises();
      expect(cacheUpdates.setError).toHaveBeenCalledWith(
        expect.objectContaining({ message: 'An error occurred when updating the title' }),
      );
    });
  });
});
