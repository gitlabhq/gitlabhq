import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import CreateDashboardModal from '~/monitoring/components/create_dashboard_modal.vue';

describe('Create dashboard modal', () => {
  let wrapper;

  const defaultProps = {
    modalId: 'id',
    projectPath: 'https://localhost/',
    addDashboardDocumentationPath: 'https://link/to/docs',
  };

  const findDocsButton = () => wrapper.find('[data-testid="create-dashboard-modal-docs-button"]');
  const findRepoButton = () => wrapper.find('[data-testid="create-dashboard-modal-repo-button"]');

  const createWrapper = (props = {}, options = {}) => {
    wrapper = shallowMount(CreateDashboardModal, {
      propsData: { ...defaultProps, ...props },
      stubs: {
        GlModal,
      },
      ...options,
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  it('has button that links to the project url', async () => {
    findRepoButton().trigger('click');

    await nextTick();
    expect(findRepoButton().exists()).toBe(true);
    expect(findRepoButton().attributes('href')).toBe(defaultProps.projectPath);
  });

  it('has button that links to the docs', () => {
    expect(findDocsButton().exists()).toBe(true);
    expect(findDocsButton().attributes('href')).toBe(defaultProps.addDashboardDocumentationPath);
  });
});
