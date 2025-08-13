import { GlDisclosureDropdown } from '@gitlab/ui';
import { createMockDirective } from 'helpers/vue_mock_directive';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemsListActions from '~/work_items/components/work_item_list_actions.vue';

describe('WorkItemsListActions component', () => {
  let wrapper;

  const projectImportJiraPath = 'gitlab-org/gitlab-test/-/import/jira';

  function createComponent(injectedProperties = {}) {
    return mountExtended(WorkItemsListActions, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      provide: {
        projectImportJiraPath: null,
        ...injectedProperties,
      },
    });
  }

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findImportFromJiraLink = () => wrapper.findByTestId('import-from-jira-link');

  describe('import from jira', () => {
    describe('when projectImportJiraPath is provided', () => {
      beforeEach(() => {
        wrapper = createComponent({ projectImportJiraPath });
      });

      it('renders the import from Jira dropdown item', () => {
        expect(findImportFromJiraLink().exists()).toBe(true);
      });

      it('passes the proper path to the link', () => {
        expect(findImportFromJiraLink().props('item').href).toBe(projectImportJiraPath);
      });
    });

    describe('when projectImportJiraPath is not provided', () => {
      beforeEach(() => {
        wrapper = createComponent({ projectImportJiraPath: null });
      });

      it('does not render the dropdown', () => {
        expect(findDropdown().exists()).toBe(false);
      });
    });
  });
});
