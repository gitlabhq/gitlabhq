import { GlAlert, GlDrawer, GlLoadingIcon, GlFormCheckbox } from '@gitlab/ui';
import AvailableVisualizationsDrawer from '~/vue_shared/components/customizable_dashboard/dashboard_editor/available_visualizations_drawer.vue';
import api from '~/api';
import { humanize } from '~/lib/utils/text_utility';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { stubComponent } from 'helpers/stub_component';
import { createVisualization } from '../mock_data';

jest.mock('~/lib/utils/dom_utils', () => ({
  getContentWrapperHeight: () => '123px',
}));

describe('AvailableVisualizationsDrawer', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const allTypes = ['SingleStat', 'LineChart', 'DataTable', 'BarChart'];

  const createVisualizations = (types = ['SingleStat']) => {
    const visualization = createVisualization();

    return types.map((type, index) => ({
      ...visualization,
      slug: `${visualization.slug}-${index}`,
      type,
    }));
  };

  const stubs = {
    GlDrawer,
    GlFormCheckbox: stubComponent(GlFormCheckbox, {
      props: ['value'],
      template: `<div><input type="checkbox" /><slot></slot></div>`,
    }),
  };

  const createWrapper = (props = {}, mountFn = shallowMountExtended, options = {}) => {
    wrapper = mountFn(AvailableVisualizationsDrawer, {
      propsData: {
        visualizations: [],
        loading: false,
        hasError: false,
        open: false,
        ...props,
      },
      stubs: mountFn === shallowMountExtended ? stubs : {},
      ...options,
    });
  };

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findAddButton = () => wrapper.findByTestId('add-button');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findListItems = () => wrapper.findAll('li');
  const findListItemBySlug = (slug) => wrapper.findByTestId(`list-item-${slug}`);
  const findCheckboxBySlug = (slug) => findListItemBySlug(slug).findComponent(GlFormCheckbox);
  const findCategoryTitles = () => wrapper.findAllByTestId('category-title');
  const findAlert = () => wrapper.findComponent(GlAlert);

  describe('default behaviour', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the drawer', () => {
      expect(findDrawer().props()).toMatchObject({
        open: false,
        headerHeight: '0',
        zIndex: DRAWER_Z_INDEX,
      });
    });
  });

  describe('when the drawer is open', () => {
    beforeEach(() => {
      jest.spyOn(api, 'trackRedisCounterEvent').mockImplementation(() => {});
      createWrapper({ open: true });
    });

    it('renders the opened drawer', () => {
      expect(findDrawer().text()).toContain('Add visualization');
      expect(findDrawer().props('headerHeight')).toBe(getContentWrapperHeight());
    });

    it('disables the add button', () => {
      expect(findAddButton().attributes().disabled).toBe('true');
    });

    it('emits close event when the drawer is closed', async () => {
      await findDrawer().vm.$emit('close');

      expect(wrapper.emitted('close')).toEqual([[]]);
    });

    it('does not render the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('when the drawer is open and is loading', () => {
    beforeEach(() => {
      createWrapper({ open: true, loading: true });
    });

    it('renders the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not render any list items', () => {
      expect(findListItems()).toHaveLength(0);
    });
  });

  describe('when the drawer is open and visualizations have been loaded', () => {
    const visualizations = createVisualizations(allTypes);

    beforeEach(() => {
      createWrapper({ open: true, loading: false, visualizations }, shallowMountExtended, {
        attachTo: document.body,
      });
    });

    it('does not render the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders the category titles', () => {
      expect(findCategoryTitles().wrappers).toHaveLength(3);
    });

    it('renders list items for each visualization', () => {
      expect(findListItems()).toHaveLength(visualizations.length);
    });

    it('renders a checkbox for each visualization', () => {
      visualizations.forEach((visualization) => {
        const checkbox = findCheckboxBySlug(visualization.slug);

        expect(checkbox.text()).toContain(humanize(visualization.slug));
        expect(checkbox.props('value')).toStrictEqual(visualization);
      });
    });

    it('sets focus on the first visualization checkbox', () => {
      expect(findListItems().at(0).find('input').element).toStrictEqual(document.activeElement);
    });

    describe('and a user clicks on some list items', () => {
      beforeEach(async () => {
        await findListItemBySlug(visualizations[0].slug).trigger('click');
        await findListItemBySlug(visualizations[1].slug).trigger('click');
      });

      it('enables the add button', () => {
        expect(findAddButton().attributes('disabled')).toBeUndefined();
      });

      it('emits the selected visualizations when the add button is clicked', async () => {
        await findAddButton().vm.$emit('click');

        expect(wrapper.emitted('select')[0][0]).toMatchObject([
          visualizations[0],
          visualizations[1],
        ]);
      });

      it('clears the selected visualizations after add button is clicked', async () => {
        await findAddButton().vm.$emit('click');

        expect(findAddButton().attributes().disabled).toBe('true');
      });

      it('deselects the selected visualizations when the same list items are clicked again', async () => {
        await findListItemBySlug(visualizations[0].slug).trigger('click');
        await findListItemBySlug(visualizations[1].slug).trigger('click');

        expect(findAddButton().attributes().disabled).toBe('true');
      });
    });

    describe('and a user selects using checkboxes', () => {
      beforeEach(async () => {
        createWrapper({ open: true, loading: false, visualizations }, mountExtended);

        await findCheckboxBySlug(visualizations[2].slug).find('input').setChecked(true);
        await findCheckboxBySlug(visualizations[3].slug).find('input').setChecked(true);
      });

      it('enables the add button', () => {
        expect(findAddButton().attributes('disabled')).toBeUndefined();
      });

      it('emits the selected visualizations when the add button is clicked', async () => {
        await findAddButton().vm.$emit('click');

        expect(wrapper.emitted('select')[0][0]).toMatchObject([
          visualizations[2],
          visualizations[3],
        ]);
      });
    });
  });

  describe('when the drawer is open and there is an error', () => {
    beforeEach(() => {
      createWrapper({ open: true, loading: false, hasError: true });
    });

    it('does not render the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('does not render any list items', () => {
      expect(findListItems()).toHaveLength(0);
    });

    it('renders an error', () => {
      const alert = findAlert();

      expect(alert.exists()).toBe(true);
      expect(alert.text()).toContain(
        'Something went wrong while loading available visualizations. Refresh the page to try again.',
      );
    });
  });

  describe('category titles', () => {
    const allTitles = ['Single stats', 'Tables', 'Charts'];

    it.each`
      types                                        | categoryTitles
      ${['SingleStat']}                            | ${['Single stats']}
      ${['SingleStat', 'DataTable']}               | ${['Single stats', 'Tables']}
      ${['SingleStat', 'DataTable']}               | ${['Single stats', 'Tables']}
      ${['SingleStat', 'DataTable', 'Line Chart']} | ${allTitles}
      ${['SingleStat', 'DataTable', 'Line Chart']} | ${allTitles}
      ${allTypes}                                  | ${allTitles}
      ${[...allTypes, 'FooBar']}                   | ${allTitles}
    `('renders the titles $categoryTitles for types $types', async ({ types, categoryTitles }) => {
      await createWrapper({
        open: true,
        loading: false,
        visualizations: createVisualizations(types),
      });

      const renderedTitles = findCategoryTitles().wrappers.map((w) => w.text());

      expect(renderedTitles.sort()).toStrictEqual(categoryTitles.sort());
    });
  });
});
