import { nextTick } from 'vue';
import { GlSkeletonLoader, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { isLoggedIn } from '~/lib/utils/common_utils';
import DesignToolbar from '~/work_items/components/design_management/design_preview/design_toolbar.vue';
import CloseButton from '~/work_items/components/design_management/design_preview/close_button.vue';
import ArchiveDesignButton from '~/work_items/components/design_management/archive_design_button.vue';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import TodosToggle from '~/work_items/components/shared/todos_toggle.vue';
import mockDesign from './mock_design';

jest.mock('~/lib/utils/common_utils');

describe('DesignToolbar', () => {
  let wrapper;
  const workItemTitle = 'Test title';

  function createComponent({
    isLoading = false,
    design = mockDesign,
    isLatestVersion = true,
  } = {}) {
    wrapper = shallowMountExtended(DesignToolbar, {
      propsData: {
        workItemTitle,
        isLoading,
        design,
        isSidebarOpen: true,
        designFilename: design.filename,
        isLatestVersion,
      },
      isLoggedIn: isLoggedIn(),
    });
  }

  beforeEach(() => {
    isLoggedIn.mockReturnValue(true);
  });

  const findWorkItemTodos = () => wrapper.findComponent(TodosToggle);
  const findImportedBadge = () => wrapper.findComponent(ImportedBadge);
  const findGlSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findDesignTitle = () => wrapper.find('h2').text();

  it('renders skeleton loader when loading', () => {
    createComponent({ isLoading: true });

    expect(findGlSkeletonLoader().exists()).toBe(true);
  });

  it('does mot render skeleton loader when loaded', () => {
    createComponent();

    expect(findGlSkeletonLoader().exists()).toBe(false);
  });

  it('renders issue title and design filename', () => {
    createComponent();

    expect(findDesignTitle()).toContain(workItemTitle);
    expect(findDesignTitle()).toContain(mockDesign.filename);
  });

  it('renders download button with correct link', () => {
    createComponent();

    expect(wrapper.findComponent(GlButton).attributes('href')).toBe(mockDesign.image);
  });

  it('renders close button', () => {
    createComponent();

    expect(wrapper.findComponent(CloseButton).exists()).toBe(true);
  });

  it('renders archive design button', () => {
    createComponent();

    expect(wrapper.findComponent(ArchiveDesignButton).exists()).toBe(true);
  });

  it('does not render archive design button if the version is not the latest', () => {
    createComponent({ isLatestVersion: false });

    expect(wrapper.findComponent(ArchiveDesignButton).exists()).toBe(false);
  });

  it('renders imported badge when design is imported', () => {
    createComponent();

    expect(findImportedBadge().exists()).toBe(true);
  });

  it('does not render imported badge when design is not imported', () => {
    createComponent({ design: { ...mockDesign, imported: false } });

    expect(findImportedBadge().exists()).toBe(false);
  });

  it('emits toggle-sidebar event when clicking on toggle sidebar button', async () => {
    createComponent();

    wrapper.findByTestId('toggle-design-sidebar').vm.$emit('click');
    await nextTick();

    expect(wrapper.emitted('toggle-sidebar')).toHaveLength(1);
  });

  it('renders todos widget if logged in', () => {
    createComponent();

    expect(findWorkItemTodos().props('itemId')).toEqual(mockDesign.id);
    expect(findWorkItemTodos().props('currentUserTodos')).toEqual([]);
  });

  it('emits `todosUpdated` event when todo button is toggled', () => {
    createComponent();

    findWorkItemTodos().vm.$emit('todosUpdated');

    expect(wrapper.emitted('todosUpdated')).toHaveLength(1);
  });

  describe('when user is not logged in', () => {
    beforeEach(() => {
      isLoggedIn.mockReturnValue(false);
      createComponent();
    });

    it('does not renders todos component', () => {
      expect(findWorkItemTodos().exists()).toBe(false);
    });
  });
});
