import { GlButtonGroup } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { VIEW_MODE_LIST, VIEW_MODE_TABLE } from '~/work_items/constants';
import WorkItemViewModeToggle from '~/work_items/components/work_item_view_mode_toggle.vue';

// Pin this to the CE view modes regardless of which alias environment the suite runs
// under (FOSS_ONLY or not) — the CE/EE difference itself is covered by view_modes_spec.js.
jest.mock('ee_else_ce/work_items/view_modes', () => jest.requireActual('~/work_items/view_modes'));

describe('WorkItemViewModeToggle', () => {
  let wrapper;

  const findToggles = () => wrapper.findAllComponents(GlButtonGroup);
  const findIconButton = (viewMode) => wrapper.findComponentByTestId(`view-mode-icon-${viewMode}`);
  const findLabelButton = (viewMode) =>
    wrapper.findComponentByTestId(`view-mode-label-${viewMode}`);

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(WorkItemViewModeToggle, {
      propsData: {
        viewMode: VIEW_MODE_LIST,
        ...props,
      },
      provide: {
        glFeatures: { planningViewTable: false },
        ...provide,
      },
    });
  };

  it('does not render when the table view mode is disabled', () => {
    createComponent();

    expect(findToggles()).toHaveLength(0);
  });

  describe('when planningViewTable feature flag is enabled', () => {
    beforeEach(() => {
      createComponent({ provide: { glFeatures: { planningViewTable: true } } });
    });

    it('renders an icon-only group hidden at the md breakpoint and a label group hidden below it', () => {
      expect(findToggles()).toHaveLength(2);
      expect(findToggles().at(0).classes()).toContain('@md/panel:gl-hidden');
      expect(findToggles().at(1).classes()).toEqual(
        expect.arrayContaining(['gl-hidden', '@md/panel:gl-inline-flex']),
      );
    });

    it.each`
      viewMode           | icon               | label
      ${VIEW_MODE_LIST}  | ${'list-bulleted'} | ${'List'}
      ${VIEW_MODE_TABLE} | ${'table'}         | ${'Table'}
    `(
      'renders $label as a $icon icon-only button labelled for assistive tech',
      ({ viewMode, icon, label }) => {
        expect(findIconButton(viewMode).props('icon')).toBe(icon);
        expect(findIconButton(viewMode).attributes('aria-label')).toBe(label);
        expect(findIconButton(viewMode).attributes('title')).toBe(label);
      },
    );

    it.each`
      viewMode           | label
      ${VIEW_MODE_LIST}  | ${'List'}
      ${VIEW_MODE_TABLE} | ${'Table'}
    `('renders $label as text on the label button, without an icon', ({ viewMode, label }) => {
      expect(findLabelButton(viewMode).text()).toBe(label);
      expect(findLabelButton(viewMode).props('icon')).toBe('');
    });

    it('emits toggle-view-mode with the clicked value from the icon button', () => {
      findIconButton(VIEW_MODE_TABLE).vm.$emit('click');

      expect(wrapper.emitted('toggle-view-mode')).toEqual([[VIEW_MODE_TABLE]]);
    });

    it('emits toggle-view-mode with the clicked value from the label button', () => {
      findLabelButton(VIEW_MODE_TABLE).vm.$emit('click');

      expect(wrapper.emitted('toggle-view-mode')).toEqual([[VIEW_MODE_TABLE]]);
    });

    describe('when the current view mode is table', () => {
      beforeEach(() => {
        createComponent({
          props: { viewMode: VIEW_MODE_TABLE },
          provide: { glFeatures: { planningViewTable: true } },
        });
      });

      it('marks that view mode as pressed and selected on both variants', () => {
        expect(findIconButton(VIEW_MODE_TABLE).props('selected')).toBe(true);
        expect(findIconButton(VIEW_MODE_TABLE).attributes('aria-pressed')).toBe('true');
        expect(findIconButton(VIEW_MODE_LIST).props('selected')).toBe(false);
        expect(findIconButton(VIEW_MODE_LIST).attributes('aria-pressed')).toBe('false');

        expect(findLabelButton(VIEW_MODE_TABLE).props('selected')).toBe(true);
        expect(findLabelButton(VIEW_MODE_TABLE).attributes('aria-pressed')).toBe('true');
        expect(findLabelButton(VIEW_MODE_LIST).props('selected')).toBe(false);
        expect(findLabelButton(VIEW_MODE_LIST).attributes('aria-pressed')).toBe('false');
      });
    });
  });
});
