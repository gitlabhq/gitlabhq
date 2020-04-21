import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import JiraImportSetup from '~/jira_import/components/jira_import_setup.vue';

describe('JiraImportSetup', () => {
  let wrapper;

  const getGlEmptyStateAttribute = attribute => wrapper.find(GlEmptyState).attributes(attribute);

  beforeEach(() => {
    wrapper = shallowMount(JiraImportSetup, {
      propsData: {
        illustration: 'illustration.svg',
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('contains illustration', () => {
    expect(getGlEmptyStateAttribute('svgpath')).toBe('illustration.svg');
  });

  it('contains a description', () => {
    const description = 'You will first need to set up Jira Integration to use this feature.';
    expect(getGlEmptyStateAttribute('description')).toBe(description);
  });

  it('contains button text', () => {
    expect(getGlEmptyStateAttribute('primarybuttontext')).toBe('Set up Jira Integration');
  });
});
