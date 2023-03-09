import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import JiraImportSetup from '~/jira_import/components/jira_import_setup.vue';
import { illustration, jiraIntegrationPath } from '../mock_data';

describe('JiraImportSetup', () => {
  let wrapper;

  const getGlEmptyStateProp = (attribute) => wrapper.findComponent(GlEmptyState).props(attribute);

  beforeEach(() => {
    wrapper = shallowMount(JiraImportSetup, {
      propsData: {
        illustration,
        jiraIntegrationPath,
      },
    });
  });

  it('contains illustration', () => {
    expect(getGlEmptyStateProp('svgPath')).toBe(illustration);
  });

  it('contains a description', () => {
    const description = 'You will first need to set up Jira Integration to use this feature.';
    expect(getGlEmptyStateProp('description')).toBe(description);
  });

  it('contains button text', () => {
    expect(getGlEmptyStateProp('primaryButtonText')).toBe('Set up Jira Integration');
  });

  it('contains button link', () => {
    expect(getGlEmptyStateProp('primaryButtonLink')).toBe(jiraIntegrationPath);
  });
});
