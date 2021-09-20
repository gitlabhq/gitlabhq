import { GlButton, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { STATUSES } from '~/import_entities/constants';
import ImportActionsCell from '~/import_entities/import_groups/components/import_actions_cell.vue';
import { generateFakeEntry } from '../graphql/fixtures';

describe('import actions cell', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMount(ImportActionsCell, {
      propsData: {
        groupPathRegex: /^[a-zA-Z]+$/,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when import status is NONE', () => {
    beforeEach(() => {
      const group = generateFakeEntry({ id: 1, status: STATUSES.NONE });
      createComponent({ group });
    });

    it('renders import button', () => {
      const button = wrapper.findComponent(GlButton);
      expect(button.exists()).toBe(true);
      expect(button.text()).toBe('Import');
    });

    it('does not render icon with a hint', () => {
      expect(wrapper.findComponent(GlIcon).exists()).toBe(false);
    });
  });

  describe('when import status is FINISHED', () => {
    beforeEach(() => {
      const group = generateFakeEntry({ id: 1, status: STATUSES.FINISHED });
      createComponent({ group });
    });

    it('renders re-import button', () => {
      const button = wrapper.findComponent(GlButton);
      expect(button.exists()).toBe(true);
      expect(button.text()).toBe('Re-import');
    });

    it('renders icon with a hint', () => {
      const icon = wrapper.findComponent(GlIcon);
      expect(icon.exists()).toBe(true);
      expect(icon.attributes().title).toBe(
        'Re-import creates a new group. It does not sync with the existing group.',
      );
    });
  });

  it('does not render import button when group import is in progress', () => {
    const group = generateFakeEntry({ id: 1, status: STATUSES.STARTED });
    createComponent({ group });

    const button = wrapper.findComponent(GlButton);
    expect(button.exists()).toBe(false);
  });

  it('renders import button as disabled when there are validation errors', () => {
    const group = generateFakeEntry({
      id: 1,
      status: STATUSES.NONE,
      validation_errors: [{ field: 'new_name', message: 'something ' }],
    });
    createComponent({ group });

    const button = wrapper.findComponent(GlButton);
    expect(button.props().disabled).toBe(true);
  });

  it('emits import-group event when import button is clicked', () => {
    const group = generateFakeEntry({ id: 1, status: STATUSES.NONE });
    createComponent({ group });

    const button = wrapper.findComponent(GlButton);
    button.vm.$emit('click');

    expect(wrapper.emitted('import-group')).toHaveLength(1);
  });
});
