import { nextTick } from 'vue';
import { GlDrawer } from '@gitlab/ui';
import FindingsDrawer from '~/diffs/components/shared/findings_drawer.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import {
  mockFindingDismissed,
  mockFindingDetected,
  mockProject,
  mockFindingsMultiple,
} from '../../mock_data/findings_drawer';

describe('FindingsDrawer', () => {
  let wrapper;

  const findPreviousButton = () => wrapper.findByTestId('findings-drawer-prev-button');
  const findNextButton = () => wrapper.findByTestId('findings-drawer-next-button');
  const findTitle = () => wrapper.findByTestId('findings-drawer-title');
  const createWrapper = (
    drawer = { findings: [mockFindingDetected], index: 0 },
    project = mockProject,
  ) => {
    return mountExtended(FindingsDrawer, {
      propsData: {
        drawer,
        project,
      },
    });
  };

  describe('General Rendering', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });
    it('renders without errors', () => {
      expect(wrapper.exists()).toBe(true);
    });

    it('emits close event when gl-drawer emits close event', () => {
      wrapper.findComponent(GlDrawer).vm.$emit('close');
      expect(wrapper.emitted('close')).toHaveLength(1);
    });

    it('matches the snapshot with dismissed badge', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('matches the snapshot with detected badge', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('Prev/Next Buttons with Multiple Items', () => {
    it('renders prev/next buttons when there are multiple items', () => {
      wrapper = createWrapper({ findings: mockFindingsMultiple, index: 0 });
      expect(findPreviousButton().exists()).toBe(true);
      expect(findNextButton().exists()).toBe(true);
    });

    it('does not render prev/next buttons when there is only one item', () => {
      wrapper = createWrapper({ findings: [mockFindingDismissed], index: 0 });
      expect(findPreviousButton().exists()).toBe(false);
      expect(findNextButton().exists()).toBe(false);
    });

    it('calls prev method on prev button click and loops correct activeIndex', async () => {
      wrapper = createWrapper({ findings: mockFindingsMultiple, index: 0 });
      expect(findTitle().text()).toBe(`Name ${mockFindingsMultiple[0].title}`);

      await findPreviousButton().trigger('click');
      await nextTick();
      expect(findTitle().text()).toBe(`Name ${mockFindingsMultiple[2].title}`);

      await findPreviousButton().trigger('click');
      await nextTick();
      expect(findTitle().text()).toBe(`Name ${mockFindingsMultiple[1].title}`);
    });

    it('calls next method on next button click', async () => {
      wrapper = createWrapper({ findings: mockFindingsMultiple, index: 0 });
      expect(findTitle().text()).toBe(`Name ${mockFindingsMultiple[0].title}`);

      await findNextButton().trigger('click');
      await nextTick();
      expect(findTitle().text()).toBe(`Name ${mockFindingsMultiple[1].title}`);

      await findNextButton().trigger('click');
      await nextTick();
      expect(findTitle().text()).toBe(`Name ${mockFindingsMultiple[2].title}`);

      await findNextButton().trigger('click');
      await nextTick();
      expect(findTitle().text()).toBe(`Name ${mockFindingsMultiple[0].title}`);
    });
  });

  describe('Active Index Handling', () => {
    it('watcher sets active index on drawer prop change', async () => {
      wrapper = createWrapper();
      const newFinding = { findings: mockFindingsMultiple, index: 2 };

      await wrapper.setProps({ drawer: newFinding });
      await nextTick();
      expect(findTitle().text()).toBe(`Name ${mockFindingsMultiple[2].title}`);
    });
  });
});
