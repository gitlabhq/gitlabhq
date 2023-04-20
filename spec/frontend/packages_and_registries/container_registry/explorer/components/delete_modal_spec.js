import { GlSprintf, GlFormInput } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import component from '~/packages_and_registries/container_registry/explorer/components/delete_modal.vue';
import {
  REMOVE_TAG_CONFIRMATION_TEXT,
  REMOVE_TAGS_CONFIRMATION_TEXT,
  DELETE_IMAGE_CONFIRMATION_TITLE,
  DELETE_IMAGE_CONFIRMATION_TEXT,
} from '~/packages_and_registries/container_registry/explorer/constants';
import { GlModal } from '../stubs';

describe('Delete Modal', () => {
  let wrapper;

  const findModal = () => wrapper.findComponent(GlModal);
  const findDescription = () => wrapper.find('[data-testid="description"]');
  const findInputComponent = () => wrapper.findComponent(GlFormInput);

  const mountComponent = (propsData) => {
    wrapper = shallowMount(component, {
      propsData,
      stubs: {
        GlSprintf,
        GlModal,
      },
    });
  };

  const expectPrimaryActionStatus = (disabled = true) =>
    expect(findModal().props('actionPrimary')).toMatchObject(
      expect.objectContaining({
        attributes: { variant: 'danger', disabled },
      }),
    );

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

      expect(wrapper.text()).toContain(
        DELETE_IMAGE_CONFIRMATION_TEXT.replace('%{code}', '').trim(),
      );
    });

    describe('delete button', () => {
      let itemsToBeDeleted = [{ project: { path: 'foo' } }];

      it('is disabled by default', () => {
        mountComponent({ deleteImage: true });

        expectPrimaryActionStatus();
      });

      it('if the user types something different from the project path is disabled', async () => {
        mountComponent({ deleteImage: true, itemsToBeDeleted });

        findInputComponent().vm.$emit('input', 'bar');

        await nextTick();

        expectPrimaryActionStatus();
      });

      it('if the user types the project path it is enabled', async () => {
        mountComponent({ deleteImage: true, itemsToBeDeleted });

        findInputComponent().vm.$emit('input', 'foo');

        await nextTick();

        expectPrimaryActionStatus(false);
      });

      it('if the user types the image name when available', async () => {
        itemsToBeDeleted = [{ name: 'foo' }];
        mountComponent({ deleteImage: true, itemsToBeDeleted });

        findInputComponent().vm.$emit('input', 'foo');

        await nextTick();

        expectPrimaryActionStatus(false);
      });
    });
  });

  describe('when we are deleting tags', () => {
    it('delete button is enabled', () => {
      mountComponent();

      expectPrimaryActionStatus(false);
    });

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
