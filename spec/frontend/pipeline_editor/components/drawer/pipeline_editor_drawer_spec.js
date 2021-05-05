import { shallowMount } from '@vue/test-utils';
import PipelineEditorDrawer from '~/pipeline_editor/components/drawer/pipeline_editor_drawer.vue';

describe('Pipeline editor drawer', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(PipelineEditorDrawer);
  };

  const findToggleBtn = () => wrapper.find('[data-testid="toggleBtn"]');
  const findArrowIcon = () => wrapper.find('[data-testid="toggle-icon"]');
  const findCollapseText = () => wrapper.find('[data-testid="collapse-text"]');
  const findDrawerContent = () => wrapper.find('[data-testid="drawer-content"]');

  const clickToggleBtn = async () => findToggleBtn().vm.$emit('click');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when the drawer is collapsed', () => {
    beforeEach(() => {
      createComponent();
    });

    it('show the left facing arrow icon', () => {
      expect(findArrowIcon().props('name')).toBe('chevron-double-lg-left');
    });

    it('does not show the collapse text', () => {
      expect(findCollapseText().exists()).toBe(false);
    });

    it('does not show the drawer content', () => {
      expect(findDrawerContent().exists()).toBe(false);
    });

    it('can open the drawer by clicking on the toggle button', async () => {
      expect(findDrawerContent().exists()).toBe(false);

      await clickToggleBtn();

      expect(findDrawerContent().exists()).toBe(true);
    });
  });

  describe('when the drawer is expanded', () => {
    beforeEach(async () => {
      createComponent();
      await clickToggleBtn();
    });

    it('show the right facing arrow icon', () => {
      expect(findArrowIcon().props('name')).toBe('chevron-double-lg-right');
    });

    it('shows the collapse text', () => {
      expect(findCollapseText().exists()).toBe(true);
    });

    it('show the drawer content', () => {
      expect(findDrawerContent().exists()).toBe(true);
    });

    it('can close the drawer by clicking on the toggle button', async () => {
      expect(findDrawerContent().exists()).toBe(true);

      await clickToggleBtn();

      expect(findDrawerContent().exists()).toBe(false);
    });
  });
});
