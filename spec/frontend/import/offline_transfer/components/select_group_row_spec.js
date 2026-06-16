import { GlAvatar, GlFormCheckbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SelectGroupRow from '~/import/offline_transfer/components/select_group_row.vue';

describe('SelectGroupRow', () => {
  let wrapper;

  const defaultProps = {
    name: 'Flight',
  };

  const createComponent = (propsData = {}) => {
    wrapper = shallowMountExtended(SelectGroupRow, {
      propsData: { ...defaultProps, ...propsData },
    });
  };

  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findAllParagraphs = () => wrapper.findAll('p');

  it('renders the correct name', () => {
    createComponent();

    expect(wrapper.text()).toContain('Flight');
    expect(findCheckbox().props('ariaLabel')).toBe('Flight');
  });

  it('does not render a description element when description is not provided', () => {
    createComponent();

    expect(findAllParagraphs()).toHaveLength(1);
  });

  it('renders the description when provided', () => {
    createComponent({ description: 'Some description text' });

    expect(wrapper.text()).toContain('Some description text');
    expect(findAllParagraphs()).toHaveLength(2);
  });

  it('passes correct props to GlAvatar', () => {
    createComponent({ avatarUrl: 'https://example.com/avatar.png' });

    expect(findAvatar().props('src')).toBe('https://example.com/avatar.png');
    expect(findAvatar().props('entityName')).toBe('Flight');
  });

  it('checkbox is unchecked by default', () => {
    createComponent();

    expect(findCheckbox().props('checked')).toBe(false);
  });

  it('checkbox reflects the checked prop', () => {
    createComponent({ checked: true });

    expect(findCheckbox().props('checked')).toBe(true);
  });

  describe('on group select', () => {
    it('emits toggle when the row is clicked', async () => {
      createComponent();
      await wrapper.findByTestId('select-group-row').trigger('click');
      expect(wrapper.emitted('toggle')).toHaveLength(1);
    });
  });
});
