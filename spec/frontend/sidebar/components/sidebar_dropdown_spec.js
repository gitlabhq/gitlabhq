import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownText,
  GlFormInput,
  GlSearchBoxByType,
} from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { TYPE_ISSUE } from '~/issues/constants';
import SidebarDropdown from '~/sidebar/components/sidebar_dropdown.vue';
import { IssuableAttributeType } from '~/sidebar/constants';
import projectIssueMilestoneQuery from '~/sidebar/queries/project_issue_milestone.query.graphql';
import projectMilestonesQuery from '~/sidebar/queries/project_milestones.query.graphql';
import {
  emptyProjectMilestonesResponse,
  mockIssue,
  mockProjectMilestonesResponse,
  noCurrentMilestoneResponse,
} from '../mock_data';

jest.mock('~/alert');

describe('SidebarDropdown component', () => {
  let wrapper;

  const promiseData = { issuableSetAttribute: { issue: { attribute: { id: '123' } } } };
  const mutationSuccess = () => jest.fn().mockResolvedValue({ data: promiseData });

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownText = () => wrapper.findComponent(GlDropdownText);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findDropdownItemWithText = (text) =>
    findAllDropdownItems().wrappers.find((x) => x.text() === text);
  const findAttributeItems = () => wrapper.findByTestId('milestone-items');
  const findNoAttributeItem = () => wrapper.findByTestId('no-milestone-item');
  const findLoadingIconDropdown = () => wrapper.findByTestId('loading-icon-dropdown');

  const toggleDropdown = async () => {
    wrapper.vm.$refs.dropdown.show();
    findDropdown().vm.$emit('show');

    await nextTick();
    jest.runOnlyPendingTimers();
    await waitForPromises();
  };

  const createComponentWithApollo = ({
    requestHandlers = [],
    projectMilestonesSpy = jest.fn().mockResolvedValue(mockProjectMilestonesResponse),
    currentMilestoneSpy = jest.fn().mockResolvedValue(noCurrentMilestoneResponse),
  } = {}) => {
    Vue.use(VueApollo);

    wrapper = mountExtended(SidebarDropdown, {
      apolloProvider: createMockApollo([
        [projectMilestonesQuery, projectMilestonesSpy],
        [projectIssueMilestoneQuery, currentMilestoneSpy],
        ...requestHandlers,
      ]),
      propsData: {
        attrWorkspacePath: mockIssue.projectPath,
        currentAttribute: {},
        issuableType: TYPE_ISSUE,
        issuableAttribute: IssuableAttributeType.Milestone,
      },
      attachTo: document.body,
    });
  };

  const createComponent = ({
    props = {},
    data = {},
    mutationPromise = mutationSuccess,
    queries = {},
  } = {}) => {
    wrapper = mountExtended(SidebarDropdown, {
      propsData: {
        attrWorkspacePath: mockIssue.projectPath,
        currentAttribute: {},
        issuableType: TYPE_ISSUE,
        issuableAttribute: IssuableAttributeType.Milestone,
        ...props,
      },
      data() {
        return data;
      },
      mocks: {
        $apollo: {
          mutate: mutationPromise(),
          queries: {
            currentAttribute: { loading: false },
            attributesList: { loading: false },
            ...queries,
          },
        },
      },
    });
  };

  describe('when a user can edit', () => {
    describe('when user is editing', () => {
      describe('when rendering the dropdown', () => {
        it('shows a loading spinner while fetching a list of attributes', async () => {
          createComponent({
            queries: {
              attributesList: { loading: true },
            },
          });

          await toggleDropdown();

          expect(findLoadingIconDropdown().exists()).toBe(true);
        });

        describe('GlDropdownItem with the right title and id', () => {
          const id = 'id';
          const title = 'title';

          beforeEach(async () => {
            createComponent({
              props: { currentAttribute: { id, title } },
              data: { attributesList: [{ id, title }] },
            });

            await toggleDropdown();
          });

          it('does not show a loading spinner', () => {
            expect(findLoadingIconDropdown().exists()).toBe(false);
          });

          it('renders title $title', () => {
            expect(findDropdownItemWithText(title).exists()).toBe(true);
          });

          it('checks the correct dropdown item', () => {
            expect(
              findAllDropdownItems()
                .filter((w) => w.props('isChecked') === true)
                .at(0)
                .text(),
            ).toBe(title);
          });
        });

        describe('when no data is assigned', () => {
          beforeEach(async () => {
            createComponent();

            await toggleDropdown();
          });

          it('finds GlDropdownItem with "No milestone"', () => {
            expect(findNoAttributeItem().text()).toBe('No milestone');
          });

          it('"No milestone" is checked', () => {
            expect(findAllDropdownItems('No milestone').at(0).props('isChecked')).toBe(true);
          });

          it('does not render any dropdown item', () => {
            expect(findAttributeItems().exists()).toBe(false);
          });
        });

        describe('when clicking on dropdown item', () => {
          describe('when currentAttribute is equal to attribute id', () => {
            it('does not call setIssueAttribute mutation', async () => {
              createComponent({
                props: { currentAttribute: { id: 'id', title: 'title' } },
                data: { attributesList: [{ id: 'id', title: 'title' }] },
              });

              await toggleDropdown();

              findDropdownItemWithText('title').vm.$emit('click');

              expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledTimes(0);
            });
          });
        });
      });

      describe('when a user is searching', () => {
        describe('when search result is not found', () => {
          describe('when milestone', () => {
            it('renders "No milestone found"', async () => {
              createComponent();

              await toggleDropdown();

              findSearchBox().vm.$emit('input', 'non existing milestones');
              await nextTick();

              expect(findDropdownText().text()).toBe('No milestone found');
            });
          });
        });
      });
    });
  });

  describe('with mock apollo', () => {
    describe("when issuable type is 'issue'", () => {
      describe('when dropdown is expanded and user can edit', () => {
        it('renders the dropdown on clicking edit', async () => {
          createComponentWithApollo();

          await toggleDropdown();

          expect(findDropdown().isVisible()).toBe(true);
        });

        it('focuses on the input when dropdown is shown', async () => {
          createComponentWithApollo();

          await toggleDropdown();

          expect(document.activeElement).toEqual(wrapper.findComponent(GlFormInput).element);
        });

        describe('milestones', () => {
          it('should call createAlert if milestones query fails', async () => {
            createComponentWithApollo({
              projectMilestonesSpy: jest.fn().mockRejectedValue(new Error()),
            });

            await toggleDropdown();

            expect(createAlert).toHaveBeenCalledWith({
              message: wrapper.vm.i18n.listFetchError,
              captureError: true,
              error: expect.any(Error),
            });
          });

          it('only fetches attributes when dropdown is opened', async () => {
            const projectMilestonesSpy = jest
              .fn()
              .mockResolvedValueOnce(emptyProjectMilestonesResponse);
            createComponentWithApollo({ projectMilestonesSpy });

            expect(projectMilestonesSpy).not.toHaveBeenCalled();

            await toggleDropdown();

            expect(projectMilestonesSpy).toHaveBeenNthCalledWith(1, {
              fullPath: mockIssue.projectPath,
              state: 'active',
              title: '',
            });
          });

          describe('when a user is searching', () => {
            it('sends a projectMilestones query with the entered search term "foo"', async () => {
              const mockSearchTerm = 'foobar';
              const projectMilestonesSpy = jest
                .fn()
                .mockResolvedValueOnce(emptyProjectMilestonesResponse);
              createComponentWithApollo({ projectMilestonesSpy });

              await toggleDropdown();

              findSearchBox().vm.$emit('input', mockSearchTerm);
              await nextTick();
              jest.runOnlyPendingTimers(); // Account for debouncing

              expect(projectMilestonesSpy).toHaveBeenNthCalledWith(2, {
                fullPath: mockIssue.projectPath,
                state: 'active',
                title: mockSearchTerm,
              });
            });
          });
        });
      });
    });
  });
});
