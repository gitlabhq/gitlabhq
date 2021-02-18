import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import component from '~/registry/explorer/components/details_page/delete_modal.vue';
import {
  REMOVE_TAG_CONFIRMATION_TEXT,
  REMOVE_TAGS_CONFIRMATION_TEXT,
  DELETE_IMAGE_CONFIRMATION_TITLE,
  DELETE_IMAGE_CONFIRMATION_TEXT,
} from '~/registry/explorer/constants';
import { GlModal } from '../../stubs';

describe('Delete Modal', () => {
  let wrapper;

  const findModal = () => wrapper.find(GlModal);
  const findDescription = () => wrapper.find('[data-testid="description"]');

  const mountComponent = (propsData) => {
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
      glEvent      | localEvent
      ${'primary'} | ${'confirmDelete'}
      ${'cancel'}  | ${'cancelDelete'}
    `('GlModal $glEvent emits $localEvent', ({ glEvent, localEvent }) => {
      mountComponent();
      findModal().vm.$emit(glEvent);
      expect(wrapper.emitted(localEvent)).toEqual([[]]);
    });
  });

  describe('methods', () => {
    it('show calls gl-modal show', () => {
      mountComponent();
      wrapper.vm.show();
      expect(GlModal.methods.show).toHaveBeenCalled();
    });
  });

  describe('when we are deleting images', () => {
    it('has the correct title', () => {
      mountComponent({ deleteImage: true });

      expect(wrapper.text()).toContain(DELETE_IMAGE_CONFIRMATION_TITLE);
    });

    it('has the correct description', () => {
      mountComponent({ deleteImage: true });

      expect(wrapper.text()).toContain(DELETE_IMAGE_CONFIRMATION_TEXT);
    });
  });

  describe('when we are deleting tags', () => {
    describe('itemsToBeDeleted contains one element', () => {
      beforeEach(() => {
        mountComponent({ itemsToBeDeleted: [{ path: 'foo' }] });
      });

      it(`has the correct description`, () => {
        expect(findDescription().text()).toBe(
          REMOVE_TAG_CONFIRMATION_TEXT.replace('%{item}', 'foo'),
        );
      });

      it('has the correct title', () => {
        expect(wrapper.text()).toContain('Remove tag');
      });
    });

    describe('itemsToBeDeleted contains more than element', () => {
      beforeEach(() => {
        mountComponent({ itemsToBeDeleted: [{ path: 'foo' }, { path: 'bar' }] });
      });

      it(`has the correct description`, () => {
        expect(findDescription().text()).toBe(
          REMOVE_TAGS_CONFIRMATION_TEXT.replace('%{item}', '2'),
        );
      });

      it('has the correct title', () => {
        expect(wrapper.text()).toContain('Remove tags');
      });
    });
  });
});
