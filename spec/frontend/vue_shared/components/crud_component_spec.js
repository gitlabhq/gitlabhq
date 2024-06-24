import { nextTick } from 'vue';
import { GlButton, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CrudComponent from '~/vue_shared/components/crud_component.vue';

describe('CRUD Component', () => {
  let wrapper;

  const createComponent = (propsData, slots = {}) => {
    wrapper = shallowMountExtended(CrudComponent, {
      propsData: {
        title: 'CRUD Component title',
        ...propsData,
      },
      scopedSlots: {
        ...slots,
      },
      stubs: { GlButton, GlIcon },
    });
  };

  const findTitle = () => wrapper.findByTestId('crud-title');
  const findDescription = () => wrapper.findByTestId('crud-description');
  const findCount = () => wrapper.findByTestId('crud-count');
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findFormToggle = () => wrapper.findByTestId('crud-form-toggle');
  const findActions = () => wrapper.findByTestId('crud-actions');
  const findForm = () => wrapper.findByTestId('crud-form');
  const findBody = () => wrapper.findByTestId('crud-body');
  const findFooter = () => wrapper.findByTestId('crud-footer');
  const findPagination = () => wrapper.findByTestId('crud-pagination');

  it('renders title', () => {
    createComponent();

    expect(findTitle().text()).toBe('CRUD Component title');
  });

  it('renders description', () => {
    createComponent({ description: 'Description' });

    expect(findDescription().text()).toBe('Description');
  });

  it('renders `description` slot', () => {
    createComponent({}, { description: '<p>Description slot</p>' });

    expect(findDescription().text()).toBe('Description slot');
  });

  it('renders count and icon', () => {
    createComponent({ count: 99, icon: 'rocket' });

    expect(findCount().text()).toBe('99');
    expect(findIcon().props('name')).toBe('rocket');
  });

  it('renders `actions` slot', () => {
    createComponent({}, { actions: '<p>Actions slot</p>' });

    expect(findActions().text()).toBe('Actions slot');
  });

  it('renders and shows `form` slot', async () => {
    createComponent({ toggleText: 'Form action toggle' }, { form: '<p>Form slot</p>' });

    expect(findForm().exists()).toBe(false);
    expect(findFormToggle().text()).toBe('Form action toggle');

    findFormToggle().vm.$emit('click');
    await nextTick();

    expect(findForm().text()).toBe('Form slot');
  });

  it('renders `body` slot', () => {
    createComponent({}, { default: '<p>Body slot</p>' });

    expect(findBody().text()).toBe('Body slot');
  });

  it('renders `footer` slot', () => {
    createComponent({}, { footer: '<p>Footer slot</p>' });

    expect(findFooter().text()).toBe('Footer slot');
  });

  it('renders `pagination` slot', () => {
    createComponent({}, { pagination: '<p>Pagination slot</p>' });

    expect(findPagination().text()).toBe('Pagination slot');
  });
});
