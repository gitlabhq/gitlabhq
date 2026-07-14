import { GlAvatar, GlFormCheckbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupRow from '~/import/offline_transfer/components/group_row.vue';

describe('GroupRow', () => {
  let wrapper;

  const defaultProps = {
    name: 'Flight',
  };

  const createComponent = (propsData = {}) => {
    wrapper = shallowMountExtended(GroupRow, {
      propsData: { ...defaultProps, ...propsData },
    });
  };

  const findCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findRow = () => wrapper.findByTestId('group-row');
  const findAllParagraphs = () => wrapper.findAll('p');

  it('renders the correct name', () => {
    createComponent();

    expect(wrapper.text()).toContain('Flight');
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

  describe('when not selectable (default)', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render a checkbox', () => {
      expect(findCheckbox().exists()).toBe(false);
    });

    it('does not apply the pointer cursor', () => {
      expect(findRow().classes()).not.toContain('gl-cursor-pointer');
    });

    it('does not emit toggle when clicked', async () => {
      await findRow().trigger('click');

      expect(wrapper.emitted('toggle')).toBeUndefined();
    });
  });

  describe('when selectable', () => {
    it('renders a labelled checkbox as unchecked by default', () => {
      createComponent({ selectable: true });
      expect(findCheckbox().props('checked')).toBe(false);
      expect(findCheckbox().props('ariaLabel')).toBe('Flight');
    });

    it('applies the pointer cursor', () => {
      createComponent({ selectable: true });

      expect(findRow().classes()).toContain('gl-cursor-pointer');
    });

    it('checkbox reflects the checked prop', () => {
      createComponent({ selectable: true, checked: true });

      expect(findCheckbox().props('checked')).toBe(true);
    });

    it('emits toggle when the row is clicked', async () => {
      createComponent({ selectable: true });

      await findRow().trigger('click');

      expect(wrapper.emitted('toggle')).toHaveLength(1);
    });
  });
});
