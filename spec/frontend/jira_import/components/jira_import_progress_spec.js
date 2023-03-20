import { GlEmptyState } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import JiraImportProgress from '~/jira_import/components/jira_import_progress.vue';
import { illustration, issuesPath } from '../mock_data';

describe('JiraImportProgress', () => {
  let wrapper;

  const importProject = 'JIRAPROJECT';

  const getGlEmptyStateProp = (attribute) => wrapper.findComponent(GlEmptyState).props(attribute);

  const getParagraphText = () => wrapper.find('p').text();

  const mountComponent = ({ mountType = 'shallowMount' } = {}) => {
    const mountFunction = mountType === 'shallowMount' ? shallowMount : mount;
    return mountFunction(JiraImportProgress, {
      propsData: {
        illustration,
        importInitiator: 'Jane Doe',
        importProject,
        importTime: '2020-04-08T12:17:25+00:00',
        issuesPath,
      },
    });
  };

  describe('empty state', () => {
    beforeEach(() => {
      wrapper = mountComponent();
    });

    it('contains illustration', () => {
      expect(getGlEmptyStateProp('svgPath')).toBe(illustration);
    });

    it('contains a title', () => {
      const title = 'Import in progress';
      expect(getGlEmptyStateProp('title')).toBe(title);
    });

    it('contains button text', () => {
      expect(getGlEmptyStateProp('primaryButtonText')).toBe('View issues');
    });

    it('contains button url', () => {
      const expected = `${issuesPath}?search=${importProject}`;
      expect(getGlEmptyStateProp('primaryButtonLink')).toBe(expected);
    });
  });

  describe('description', () => {
    beforeEach(() => {
      wrapper = mountComponent({ mountType: 'mount' });
    });

    it('shows who initiated the import', () => {
      expect(getParagraphText()).toContain('Import started by: Jane Doe');
    });

    it('shows the time of import', () => {
      expect(getParagraphText()).toContain('Time of import: Apr 8, 2020 12:17pm UTC');
    });

    it('shows the project key of the import', () => {
      expect(getParagraphText()).toContain('Jira project: JIRAPROJECT');
    });
  });
});
