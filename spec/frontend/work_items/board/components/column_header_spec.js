import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ColumnHeader from '~/work_items/board/components/column_header.vue';
import { getAdaptiveStatusColor } from '~/lib/utils/color_utils';
import { mockStatus } from '../mock_data';

jest.mock('~/lib/utils/color_utils', () => ({
  getAdaptiveStatusColor: jest.fn(() => '#89888d'),
}));

describe('ColumnHeader', () => {
  let wrapper;

  const findIcons = () => wrapper.findAllComponents(GlIcon);
  const findIconByName = (name) => findIcons().wrappers.find((icon) => icon.props('name') === name);
  const findHeading = () => wrapper.findByTestId('column-header-name');
  const findCount = () => wrapper.findByTestId('column-header-count');

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(ColumnHeader, {
      propsData: {
        value: mockStatus,
        groupProperty: 'status',
        count: 5,
        ...props,
      },
    });
  };

  describe('value.name', () => {
    it('renders the value name in the heading', () => {
      createComponent();

      expect(findHeading().text()).toBe('To do');
    });
  });

  describe('count', () => {
    it('renders the count alongside the work-items icon', () => {
      createComponent({ props: { count: 42 } });

      expect(findCount().text()).toBe('42');
      expect(findIconByName('work-items')).not.toBeUndefined();
    });
  });

  describe('chrome icons', () => {
    it.each(['chevron-down', 'work-items', 'ellipsis_v', 'plus'])(
      'renders the "%s" icon',
      (iconName) => {
        createComponent();

        expect(findIconByName(iconName)).not.toBeUndefined();
      },
    );
  });

  describe('status icon', () => {
    describe('when groupProperty is "status" and value.iconName is set', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders an icon with the value.iconName', () => {
        expect(findIconByName('status-waiting')).not.toBeUndefined();
      });

      it('passes the adaptive color as inline style', () => {
        expect(getAdaptiveStatusColor).toHaveBeenCalledWith('#737278');
        expect(findIconByName('status-waiting').element.style.color).toBe('rgb(137, 136, 141)');
      });
    });

    describe('when value.color is not set', () => {
      it('renders the icon without an inline color style', () => {
        createComponent({ props: { value: { ...mockStatus, color: null } } });

        expect(findIconByName('status-waiting').element.style.color).toBe('');
      });
    });

    describe('when groupProperty is not "status"', () => {
      it('does not render the status icon', () => {
        createComponent({ props: { groupProperty: 'label' } });

        expect(findIconByName('status-waiting')).toBeUndefined();
      });
    });

    describe('when value.iconName is empty', () => {
      it('does not render the status icon', () => {
        createComponent({ props: { value: { ...mockStatus, iconName: '' } } });

        expect(findIconByName('status-waiting')).toBeUndefined();
      });
    });
  });
});
