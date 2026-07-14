import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BlameCommitInfo from '~/vue_shared/components/source_viewer/components/blame_commit_info.vue';
import BlameInfo from '~/vue_shared/components/source_viewer/components/blame_info.vue';
import { PanelBreakpointInstance } from '~/panel_breakpoint_instance';
import * as utils from '~/vue_shared/components/source_viewer/utils';
import AccessiblePanelResizer from '~/vue_shared/components/accessible_panel_resizer.vue';
import { BLAME_DATA_MOCK } from '../mock_data';

describe('BlameInfo component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(BlameInfo, {
      propsData: {
        blameInfo: BLAME_DATA_MOCK,
        projectPath: 'gitlab-org/gitlab',
        ...props,
      },
    });
  };

  const findBlameCommitInfoComponents = () => wrapper.findAllComponents(BlameCommitInfo);
  const findBlameWrappers = () => wrapper.findAll('.blame-commit-wrapper');
  const findIndicatorHeight = (index) =>
    findBlameWrappers().at(index).element.style.getPropertyValue('--blame-indicator-height');
  const findPanelResizer = () => wrapper.findComponent(AccessiblePanelResizer);

  beforeEach(() => createComponent());

  afterEach(() => {
    localStorage.clear();
    jest.restoreAllMocks();
  });

  it('renders a BlameCommitInfo component for each blame entry', () => {
    expect(findBlameCommitInfoComponents()).toHaveLength(BLAME_DATA_MOCK.length);
  });

  it.each(BLAME_DATA_MOCK)(
    'sets the correct data and positioning for blame entry at index $index',
    ({ commit, index, blameOffset, previousPath }) => {
      const blameCommitInfo = findBlameCommitInfoComponents().at(index);

      expect(blameCommitInfo.props('commit')).toEqual(commit);
      expect(blameCommitInfo.props('previousPath')).toBe(previousPath);
      expect(blameCommitInfo.props('projectPath')).toBe('gitlab-org/gitlab');
      expect(blameCommitInfo.element.style.top).toBe(blameOffset);
    },
  );

  describe('blame age indicator', () => {
    it('renders an indicator per each BlameCommitInfo component', () => {
      expect(findBlameWrappers()).toHaveLength(findBlameCommitInfoComponents().length);
    });

    it.each(BLAME_DATA_MOCK.map((_, index) => [index]))(
      'sets the position to the same value as BlameCommitInfo component at index %i',
      (index) => {
        const blameWrapperTop = findBlameWrappers()
          .at(index)
          .element.style.getPropertyValue('--blame-indicator-top');
        const blameCommitInfoTop = findBlameCommitInfoComponents().at(index).element.style.top;

        expect(blameWrapperTop).toBe(blameCommitInfoTop);
        expect(blameWrapperTop).toBe(BLAME_DATA_MOCK[index].blameOffset);
      },
    );

    it('sets correct blame indicator colors based on age class', () => {
      const firstWrapper = findBlameWrappers().at(0);
      const expectedColor = 'var(--gl-color-data-blue-50)'; // blame-commit-age-9

      expect(firstWrapper.element.style.getPropertyValue('--blame-indicator-color')).toBe(
        expectedColor,
      );
    });

    describe('indicator height', () => {
      const singleLineGroup = [
        { lineno: 1, span: 1, commit: { author: 'A', sha: 'a' }, index: 0, blameOffset: '0px' },
      ];

      it('bounds the height to the next group start (lineno + span) when it is rendered', () => {
        // Group spans lines 1..5, next group's first line (6) is rendered at 100px.
        jest.spyOn(utils, 'calculateBlameOffset').mockReturnValue('100px');

        createComponent({
          blameInfo: [
            { lineno: 1, span: 5, commit: { author: 'A', sha: 'a' }, index: 0, blameOffset: '0px' },
          ],
        });

        expect(utils.calculateBlameOffset).toHaveBeenCalledWith(6);
        expect(findIndicatorHeight(0)).toBe('100px');
      });

      it('does not stretch across a gap when the group end line is in an unloaded chunk', () => {
        jest.spyOn(utils, 'calculateBlameOffset').mockReturnValue(null);

        createComponent({
          blameInfo: [
            { lineno: 1, span: 3, commit: { author: 'A', sha: 'a' }, index: 0, blameOffset: '0px' },
            {
              lineno: 900,
              span: 1,
              commit: { author: 'B', sha: 'b' },
              index: 1,
              blameOffset: '9000px',
            },
          ],
        });

        expect(findIndicatorHeight(0)).toBe('0px');
      });

      it('does not throw and falls back when span data is unavailable', () => {
        jest.spyOn(utils, 'calculateBlameOffset').mockReturnValue(null);

        createComponent({
          blameInfo: [
            { lineno: 1, commit: { author: 'A', sha: 'a' }, index: 0, blameOffset: '0px' },
          ],
        });

        // No span -> calculateBlameOffset(lineno + span) is never evaluated for the
        // group-bounded path; height resolves via the legacy containerHeight path.
        expect(findIndicatorHeight(0)).toBe('0px');
      });

      it('never produces a negative height', () => {
        jest.spyOn(utils, 'calculateBlameOffset').mockReturnValue('0px');

        createComponent({ blameInfo: singleLineGroup });

        expect(findIndicatorHeight(0)).toBe('0px');
      });
    });

    it('hides blame indicators from screen readers', () => {
      const wrappers = findBlameWrappers();
      for (let i = 0; i < wrappers.length; i += 1) {
        expect(wrappers.at(i).attributes('aria-hidden')).toBe('true');
      }
    });

    describe('when blameInfo changes', () => {
      const extendedBlameData = [
        ...BLAME_DATA_MOCK,
        { lineno: 4, commit: { author: 'John', sha: 'jkl' }, index: 3, blameOffset: '3px' },
      ];

      it('recalculates heights when new blame data is added', async () => {
        expect(findBlameWrappers()).toHaveLength(3);
        // setProps used to test reactivity of the component
        await wrapper.setProps({ blameInfo: extendedBlameData });
        await nextTick();

        expect(findBlameWrappers()).toHaveLength(4);
      });
    });
  });

  describe('panel resizer', () => {
    it('updates width when resizer emits update:size', async () => {
      createComponent();

      expect(wrapper.attributes('style')).toContain('width: 400px');

      findPanelResizer().vm.$emit('input', 520);
      await nextTick();

      expect(wrapper.attributes('style')).toContain('width: 520px');
    });

    it('restores width from localStorage on mount and saves new width to localStorage', async () => {
      localStorage.setItem('blame-column-width', '505');
      createComponent();
      await nextTick();

      expect(wrapper.attributes('style')).toContain('width: 505px');

      findPanelResizer().vm.$emit('resize-end', 600);
      await nextTick();

      expect(localStorage.getItem('blame-column-width')).toBe('600');
    });

    it('uses default width on non desktop view', async () => {
      jest.spyOn(PanelBreakpointInstance, 'isDesktop').mockReturnValue(true);
      createComponent();
      await nextTick();

      expect(wrapper.attributes('style')).toContain('width: 400px');
    });

    it('uses minimum width on non desktop view', async () => {
      jest.spyOn(PanelBreakpointInstance, 'isDesktop').mockReturnValue(false);
      createComponent();
      await nextTick();

      expect(wrapper.attributes('style')).toContain('width: 250px');
    });

    describe('resize listener', () => {
      it('registers a resize listener on mount', () => {
        jest.spyOn(PanelBreakpointInstance, 'addResizeListener');
        createComponent();

        expect(PanelBreakpointInstance.addResizeListener).toHaveBeenCalledWith(
          wrapper.vm.handlePanelResize,
        );
      });

      it('removes the resize listener on destroy', () => {
        jest.spyOn(PanelBreakpointInstance, 'removeResizeListener');
        createComponent();
        wrapper.destroy();

        expect(PanelBreakpointInstance.removeResizeListener).toHaveBeenCalledWith(
          wrapper.vm.handlePanelResize,
        );
      });

      it('updates isDesktop and restores width when panel is resized to desktop', async () => {
        jest.spyOn(PanelBreakpointInstance, 'addResizeListener');
        jest.spyOn(PanelBreakpointInstance, 'isDesktop').mockReturnValue(false);
        createComponent();
        await nextTick();

        expect(wrapper.attributes('style')).toContain('width: 250px');
        expect(findPanelResizer().exists()).toBe(false);

        jest.spyOn(PanelBreakpointInstance, 'isDesktop').mockReturnValue(true);
        localStorage.setItem('blame-column-width', '520');

        const handler = PanelBreakpointInstance.addResizeListener.mock.calls[0][0];
        handler();
        await nextTick();

        expect(wrapper.attributes('style')).toContain('width: 520px');
        expect(findPanelResizer().exists()).toBe(true);
      });

      it('sets minimum width and hides resizer when panel is resized to mobile', async () => {
        jest.spyOn(PanelBreakpointInstance, 'addResizeListener');
        jest.spyOn(PanelBreakpointInstance, 'isDesktop').mockReturnValue(true);
        createComponent();

        expect(wrapper.attributes('style')).toContain('width: 400px');
        expect(findPanelResizer().exists()).toBe(true);

        PanelBreakpointInstance.isDesktop.mockReturnValue(false);
        const handler = PanelBreakpointInstance.addResizeListener.mock.calls[0][0];
        handler();
        await nextTick();

        expect(wrapper.attributes('style')).toContain('width: 250px');
        expect(findPanelResizer().exists()).toBe(false);
      });
    });
  });
});
