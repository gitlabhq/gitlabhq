import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
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

  afterEach(() => {
    wrapper.destroy();
  });

  it('has button that links to the project url', () => {
    findRepoButton().trigger('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(findRepoButton().exists()).toBe(true);
      expect(findRepoButton().attributes('href')).toBe(defaultProps.projectPath);
    });
  });

  it('has button that links to the docs', () => {
    expect(findDocsButton().exists()).toBe(true);
    expect(findDocsButton().attributes('href')).toBe(defaultProps.addDashboardDocumentationPath);
  });
});
