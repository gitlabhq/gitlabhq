import { GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import GraphGroup from '~/monitoring/components/graph_group.vue';

describe('Graph group component', () => {
  let wrapper;

  const findGroup = () => wrapper.findComponent({ ref: 'graph-group' });
  const findContent = () => wrapper.findComponent({ ref: 'graph-group-content' });
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findCaretIcon = () => wrapper.findComponent(GlIcon);
  const findToggleButton = () => wrapper.find('[data-testid="group-toggle-button"]');

  const createComponent = (propsData) => {
    wrapper = shallowMount(GraphGroup, {
      propsData,
    });
  };

  describe('When group is not collapsed', () => {
    beforeEach(() => {
      createComponent({
        name: 'panel',
        collapseGroup: false,
      });
    });

    it('should not show a loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('should show the chevron-lg-down caret icon', () => {
      expect(findContent().isVisible()).toBe(true);
      expect(findCaretIcon().props('name')).toBe('chevron-lg-down');
    });

    it('should show the chevron-lg-right caret icon when the user collapses the group', async () => {
      findToggleButton().trigger('click');

      await nextTick();
      expect(findContent().isVisible()).toBe(false);
      expect(findCaretIcon().props('name')).toBe('chevron-lg-right');
    });

    it('should contain a tab index for the collapse button', () => {
      const groupToggle = findToggleButton();

      expect(groupToggle.attributes('tabindex')).toBeDefined();
    });

    it('should show the open the group when collapseGroup is set to true', async () => {
      wrapper.setProps({
        collapseGroup: true,
      });

      await nextTick();
      expect(findContent().isVisible()).toBe(true);
      expect(findCaretIcon().props('name')).toBe('chevron-lg-down');
    });
  });

  describe('When group is collapsed', () => {
    beforeEach(() => {
      createComponent({
        name: 'panel',
        collapseGroup: true,
      });
    });

    it('should show the chevron-lg-down caret icon when collapseGroup is true', () => {
      expect(findCaretIcon().props('name')).toBe('chevron-lg-right');
    });

    it('should show the chevron-lg-right caret icon when collapseGroup is false', async () => {
      findToggleButton().trigger('click');

      await nextTick();
      expect(findCaretIcon().props('name')).toBe('chevron-lg-down');
    });

    it('should call collapse the graph group content when enter is pressed on the caret icon', () => {
      const graphGroupContent = findContent();
      const button = findToggleButton();

      button.trigger('keyup.enter');

      expect(graphGroupContent.isVisible()).toBe(false);
    });
  });

  describe('When groups can not be collapsed', () => {
    beforeEach(() => {
      createComponent({
        name: 'panel',
        showPanels: false,
        collapseGroup: false,
      });
    });

    it('should not have a container when showPanels is false', () => {
      expect(findGroup().exists()).toBe(false);
      expect(findContent().exists()).toBe(true);
    });
  });

  describe('When group is loading', () => {
    beforeEach(() => {
      createComponent({
        name: 'panel',
        isLoading: true,
      });
    });

    it('should show a loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('When group does not show a panel heading', () => {
    beforeEach(() => {
      createComponent({
        name: 'panel',
        showPanels: false,
        collapseGroup: false,
      });
    });

    it('should collapse the panel content', () => {
      expect(findContent().isVisible()).toBe(true);
      expect(findCaretIcon().exists()).toBe(false);
    });

    it('should show the panel content when collapse is set to false', async () => {
      wrapper.setProps({
        collapseGroup: false,
      });

      await nextTick();
      expect(findContent().isVisible()).toBe(true);
      expect(findCaretIcon().exists()).toBe(false);
    });
  });
});
