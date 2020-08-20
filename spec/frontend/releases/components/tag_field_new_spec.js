import { mount, shallowMount } from '@vue/test-utils';
import { GlFormInput } from '@gitlab/ui';
import TagFieldNew from '~/releases/components/tag_field_new.vue';
import createStore from '~/releases/stores';
import createDetailModule from '~/releases/stores/modules/detail';
import RefSelector from '~/ref/components/ref_selector.vue';

const TEST_TAG_NAME = 'test-tag-name';
const TEST_PROJECT_ID = '1234';
const TEST_CREATE_FROM = 'test-create-from';

describe('releases/components/tag_field_new', () => {
  let store;
  let wrapper;

  const createComponent = (mountFn = shallowMount) => {
    wrapper = mountFn(TagFieldNew, {
      store,
      stubs: {
        RefSelector: true,
      },
    });
  };

  beforeEach(() => {
    store = createStore({
      modules: {
        detail: createDetailModule({
          projectId: TEST_PROJECT_ID,
        }),
      },
    });

    store.state.detail.createFrom = TEST_CREATE_FROM;

    store.state.detail.release = {
      tagName: TEST_TAG_NAME,
      assets: {
        links: [],
      },
    };
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findTagNameFormGroup = () => wrapper.find('[data-testid="tag-name-field"]');
  const findTagNameGlInput = () => findTagNameFormGroup().find(GlFormInput);
  const findTagNameInput = () => findTagNameFormGroup().find('input');

  const findCreateFromFormGroup = () => wrapper.find('[data-testid="create-from-field"]');
  const findCreateFromDropdown = () => findCreateFromFormGroup().find(RefSelector);

  describe('"Tag name" field', () => {
    describe('rendering and behavior', () => {
      beforeEach(() => createComponent());

      it('renders a label', () => {
        expect(findTagNameFormGroup().attributes().label).toBe('Tag name');
      });

      describe('when the user updates the field', () => {
        it("updates the store's release.tagName property", () => {
          const updatedTagName = 'updated-tag-name';
          findTagNameGlInput().vm.$emit('input', updatedTagName);

          return wrapper.vm.$nextTick().then(() => {
            expect(store.state.detail.release.tagName).toBe(updatedTagName);
          });
        });
      });
    });

    describe('validation', () => {
      beforeEach(() => {
        createComponent(mount);
      });

      /**
       * Utility function to test the visibility of the validation message
       * @param {'shown' | 'hidden'} state The expected state of the validation message.
       * Should be passed either 'shown' or 'hidden'
       */
      const expectValidationMessageToBe = state => {
        return wrapper.vm.$nextTick().then(() => {
          expect(findTagNameFormGroup().element).toHaveClass(
            state === 'shown' ? 'is-invalid' : 'is-valid',
          );
          expect(findTagNameFormGroup().element).not.toHaveClass(
            state === 'shown' ? 'is-valid' : 'is-invalid',
          );
        });
      };

      describe('when the user has not yet interacted with the component', () => {
        it('does not display a validation error', () => {
          findTagNameInput().setValue('');

          return expectValidationMessageToBe('hidden');
        });
      });

      describe('when the user has interacted with the component and the value is not empty', () => {
        it('does not display validation error', () => {
          findTagNameInput().trigger('blur');

          return expectValidationMessageToBe('hidden');
        });
      });

      describe('when the user has interacted with the component and the value is empty', () => {
        it('displays a validation error', () => {
          const tagNameInput = findTagNameInput();

          tagNameInput.setValue('');
          tagNameInput.trigger('blur');

          return expectValidationMessageToBe('shown');
        });
      });
    });
  });

  describe('"Create from" field', () => {
    beforeEach(() => createComponent());

    it('renders a label', () => {
      expect(findCreateFromFormGroup().attributes().label).toBe('Create from');
    });

    describe('when the user selects a git ref', () => {
      it("updates the store's createFrom property", () => {
        const updatedCreateFrom = 'update-create-from';
        findCreateFromDropdown().vm.$emit('input', updatedCreateFrom);

        return wrapper.vm.$nextTick().then(() => {
          expect(store.state.detail.createFrom).toBe(updatedCreateFrom);
        });
      });
    });
  });
});
