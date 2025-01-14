import { nextTick } from 'vue';
import { GridStack } from 'gridstack';
import { breakpoints } from '@gitlab/ui/dist/utils';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GridstackWrapper from '~/vue_shared/components/customizable_dashboard/gridstack_wrapper.vue';
import {
  GRIDSTACK_MARGIN,
  GRIDSTACK_CSS_HANDLE,
  GRIDSTACK_CELL_HEIGHT,
  GRIDSTACK_MIN_ROW,
} from '~/vue_shared/components/customizable_dashboard/constants';
import { loadCSSFile } from '~/lib/utils/css_utils';
import waitForPromises from 'helpers/wait_for_promises';
import {
  parsePanelToGridItem,
  createNewVisualizationPanel,
} from '~/vue_shared/components/customizable_dashboard/utils';
import { dashboard, builtinDashboard } from './mock_data';

const mockGridSetStatic = jest.fn();
const mockGridDestroy = jest.fn();
const mockGridLoad = jest.fn();

jest.mock('gridstack');

jest.mock('~/lib/utils/css_utils', () => ({
  loadCSSFile: jest.fn(),
}));

describe('GridstackWrapper', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;
  let panelSlots = [];

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(GridstackWrapper, {
      propsData: {
        value: dashboard,
        ...props,
      },
      scopedSlots: {
        panel(data) {
          panelSlots.push(data);
        },
      },
      attachTo: document.body,
    });
  };

  const findGridStackPanels = () => wrapper.findAllByTestId('grid-stack-panel');
  const findGridItemContentById = (panelId) =>
    wrapper.find(`[gs-id="${panelId}"]`).find('.grid-stack-item-content');
  const findPanelById = (panelId) => wrapper.find(`#${panelId}`);

  afterEach(() => {
    mockGridSetStatic.mockReset();
    mockGridDestroy.mockReset();

    panelSlots = [];
  });
  beforeEach(() => {
    GridStack.init = jest.fn().mockImplementation((config) => {
      const actualModule = jest.requireActual('gridstack');
      const instance = actualModule.GridStack.init(config);
      instance.load = mockGridLoad.mockImplementation(instance.load);
      instance.setStatic = mockGridSetStatic;
      instance.destroy = mockGridDestroy;
      return instance;
    });
  });

  describe('default behaviour', () => {
    beforeEach(() => {
      loadCSSFile.mockResolvedValue();
      createWrapper();
    });

    it('sets up GridStack', () => {
      expect(GridStack.init).toHaveBeenCalledWith({
        alwaysShowResizeHandle: true,
        staticGrid: true,
        animate: true,
        margin: GRIDSTACK_MARGIN,
        handle: GRIDSTACK_CSS_HANDLE,
        cellHeight: GRIDSTACK_CELL_HEIGHT,
        minRow: GRIDSTACK_MIN_ROW,
        columnOpts: { breakpoints: [{ w: breakpoints.md, c: 1 }] },
        float: true,
      });
    });

    it('loads the parsed dashboard config', () => {
      expect(mockGridLoad).toHaveBeenCalledWith(dashboard.panels.map(parsePanelToGridItem));
    });

    it('does not render the grab cursor on grid panels', () => {
      expect(findGridStackPanels().at(0).classes()).not.toContain('gl-cursor-grab');
    });

    it('renders a panel once it has been added', async () => {
      const newPanel = createNewVisualizationPanel(builtinDashboard.panels[0].visualization);

      expect(findPanelById(newPanel.id).exists()).toBe(false);

      wrapper.setProps({
        value: {
          ...dashboard,
          panels: [...dashboard.panels, newPanel],
        },
      });

      await waitForPromises();

      const gridItem = findGridItemContentById(newPanel.id);
      const panel = findPanelById(newPanel.id);

      expect(panel.element.parentElement).toBe(gridItem.element);
    });

    it('does not render a removed panel', async () => {
      const panelToRemove = dashboard.panels[0];

      expect(findGridStackPanels()).toHaveLength(dashboard.panels.length);
      expect(findPanelById(panelToRemove.id).exists()).toBe(true);

      wrapper.setProps({
        value: {
          ...dashboard,
          panels: dashboard.panels.filter((panel) => panel.id !== panelToRemove.id),
        },
      });

      await waitForPromises();

      expect(findGridStackPanels()).toHaveLength(dashboard.panels.length - 1);
      expect(findPanelById(panelToRemove.id).exists()).toBe(false);
    });

    describe.each(dashboard.panels.map((panel, index) => [panel, index]))(
      'for dashboard panel %#',
      (panel, index) => {
        it('renders a grid panel', () => {
          const element = findGridStackPanels().at(index);

          expect(element.attributes().id).toContain('panel-');
        });

        it('sets the panel props on the panel slot', () => {
          const { gridAttributes, ...panelProps } = panel;

          expect(panelSlots[index]).toMatchObject({ panel: panelProps });
        });

        it("renders the panel inside the grid item's content", async () => {
          const gridItem = findGridItemContentById(panel.id);

          await nextTick();

          expect(findGridStackPanels().at(index).element.parentElement).toBe(gridItem.element);
        });
      },
    );
  });

  describe('when editing = true', () => {
    beforeEach(() => {
      loadCSSFile.mockResolvedValue();
      createWrapper({ editing: true });

      return waitForPromises();
    });

    it('initializes GridStack with staticGrid = false', () => {
      expect(GridStack.init).toHaveBeenCalledWith(
        expect.objectContaining({
          staticGrid: false,
        }),
      );
    });

    it('calls GridStack.setStatic when the editing prop changes', async () => {
      wrapper.setProps({ editing: false });

      await nextTick();

      expect(mockGridSetStatic).toHaveBeenCalledWith(true);
    });

    it('renders the grab cursor on grid panels', () => {
      expect(findGridStackPanels().at(0).classes()).toContain('gl-cursor-grab');
    });
  });

  describe('when the grid changes', () => {
    beforeEach(async () => {
      loadCSSFile.mockResolvedValue();
      createWrapper();

      await waitForPromises();

      const gridEl = wrapper.find('.grid-stack').element;
      const event = new CustomEvent('change', {
        detail: [
          {
            id: dashboard.panels[1].id,
            x: 10,
            y: 20,
            w: 30,
            h: 40,
          },
        ],
      });

      gridEl.dispatchEvent(event);
    });

    it('emits the changed dashboard object', () => {
      expect(wrapper.emitted('input')).toStrictEqual([
        [
          {
            ...dashboard,
            panels: [
              dashboard.panels[0],
              {
                ...dashboard.panels[1],
                gridAttributes: {
                  ...dashboard.panels[1].gridAttributes,
                  xPos: 10,
                  yPos: 20,
                  width: 30,
                  height: 40,
                },
              },
            ],
          },
        ],
      ]);
    });
  });

  describe('when an error occurs while loading the CSS', () => {
    const sentryError = new Error('Network error');

    beforeEach(() => {
      jest.spyOn(Sentry, 'captureException');
      loadCSSFile.mockRejectedValue(sentryError);

      createWrapper();

      return waitForPromises();
    });

    it('reports the error to sentry', () => {
      expect(Sentry.captureException.mock.calls[0][0]).toStrictEqual(sentryError);
    });
  });

  describe('beforeDestroy', () => {
    beforeEach(async () => {
      loadCSSFile.mockResolvedValue();
      createWrapper();

      await waitForPromises();

      wrapper.destroy();
    });

    it('cleans up the gridstack instance', () => {
      expect(mockGridDestroy).toHaveBeenCalled();
    });
  });
});
