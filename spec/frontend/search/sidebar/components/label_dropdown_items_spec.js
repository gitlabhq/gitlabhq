import { GlFormCheckbox } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { PROCESS_LABELS_DATA } from 'jest/search/mock_data';
import LabelDropdownItems from '~/search/sidebar/components/label_filter/label_dropdown_items.vue';

Vue.use(Vuex);

describe('LabelDropdownItems', () => {
  let wrapper;

  const defaultProps = {
    labels: PROCESS_LABELS_DATA,
  };

  const createComponent = (Props = defaultProps) => {
    wrapper = shallowMountExtended(LabelDropdownItems, {
      propsData: {
        ...Props,
      },
    });
  };

  const findAllLabelItems = () => wrapper.findAllByTestId('label-filter-menu-item');
  const findFirstLabelCheckbox = () => findAllLabelItems().at(0).findComponent(GlFormCheckbox);
  const findFirstLabelTitle = () => findAllLabelItems().at(0).find('.label-title');
  const findFirstLabelColor = () =>
    findAllLabelItems().at(0).find('[data-testid="label-color-indicator"]');

  describe('Renders correctly', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders items', () => {
      expect(findAllLabelItems().exists()).toBe(true);
      expect(findAllLabelItems()).toHaveLength(defaultProps.labels.length);
    });

    it('renders items checkbox', () => {
      expect(findFirstLabelCheckbox().exists()).toBe(true);
    });

    it('renders label title', () => {
      expect(findFirstLabelTitle().exists()).toBe(true);
      expect(findFirstLabelTitle().text()).toBe(defaultProps.labels[0].title);
    });

    it('renders label color', () => {
      expect(findFirstLabelColor().exists()).toBe(true);
      expect(findFirstLabelColor().attributes('style')).toBe(
        `background-color: ${defaultProps.labels[0].color};`,
      );
    });
  });
});
