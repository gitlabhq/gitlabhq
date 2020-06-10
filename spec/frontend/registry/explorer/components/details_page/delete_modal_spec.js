import { shallowMount } from '@vue/test-utils';
import { GlSprintf } from '@gitlab/ui';
import component from '~/registry/explorer/components/details_page/delete_modal.vue';
import {
  REMOVE_TAG_CONFIRMATION_TEXT,
  REMOVE_TAGS_CONFIRMATION_TEXT,
} from '~/registry/explorer/constants';
import { GlModal } from '../../stubs';

describe('Delete Modal', () => {
  let wrapper;

  const findModal = () => wrapper.find(GlModal);
  const findDescription = () => wrapper.find('[data-testid="description"]');

  const mountComponent = propsData => {
    wrapper = shallowMount(component, {
      propsData,
      stubs: {
        GlSprintf,
        GlModal,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('contains a GlModal', () => {
    mountComponent();
    expect(findModal().exists()).toBe(true);
  });

  describe('events', () => {
    it.each`
      glEvent     | localEvent
      ${'ok'}     | ${'confirmDelete'}
      ${'cancel'} | ${'cancelDelete'}
    `('GlModal $glEvent emits $localEvent', ({ glEvent, localEvent }) => {
      mountComponent();
      findModal().vm.$emit(glEvent);
      expect(wrapper.emitted(localEvent)).toBeTruthy();
    });
  });

  describe('methods', () => {
    it('show calls gl-modal show', () => {
      mountComponent();
      wrapper.vm.show();
      expect(GlModal.methods.show).toHaveBeenCalled();
    });
  });

  describe('itemsToBeDeleted contains one element', () => {
    beforeEach(() => {
      mountComponent({ itemsToBeDeleted: [{ path: 'foo' }] });
    });
    it(`has the correct description`, () => {
      expect(findDescription().text()).toBe(REMOVE_TAG_CONFIRMATION_TEXT.replace('%{item}', 'foo'));
    });
    it('has the correct action', () => {
      expect(wrapper.text()).toContain('Remove tag');
    });
  });

  describe('itemsToBeDeleted contains more than element', () => {
    beforeEach(() => {
      mountComponent({ itemsToBeDeleted: [{ path: 'foo' }, { path: 'bar' }] });
    });
    it(`has the correct description`, () => {
      expect(findDescription().text()).toBe(REMOVE_TAGS_CONFIRMATION_TEXT.replace('%{item}', '2'));
    });
    it('has the correct action', () => {
      expect(wrapper.text()).toContain('Remove tags');
    });
  });
});
