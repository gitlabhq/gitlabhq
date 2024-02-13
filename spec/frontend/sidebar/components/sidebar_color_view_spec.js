import SidebarColorView from '~/sidebar/components/sidebar_color_view.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('SidebarColorView component', () => {
  let wrapper;

  const createComponent = ({ color = '' } = {}) => {
    wrapper = shallowMountExtended(SidebarColorView, {
      propsData: {
        color,
      },
    });
  };

  const findColorChip = () => wrapper.findByTestId('color-chip');
  const findColorValue = () => wrapper.findByTestId('color-value');

  it('renders the color chip and value', () => {
    createComponent({
      color: '#ffffff',
    });

    expect(findColorChip().attributes('style')).toBe('background-color: rgb(255, 255, 255);');
    expect(findColorValue().element.innerHTML).toBe('#ffffff');
  });
});
