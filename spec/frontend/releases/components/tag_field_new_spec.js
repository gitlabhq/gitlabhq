import { GlDropdownItem } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import TagFieldNew from '~/releases/components/tag_field_new.vue';
import createStore from '~/releases/stores';
import createEditNewModule from '~/releases/stores/modules/edit_new';

const TEST_TAG_NAME = 'test-tag-name';
const TEST_PROJECT_ID = '1234';
const TEST_CREATE_FROM = 'test-create-from';
const NONEXISTENT_TAG_NAME = 'nonexistent-tag';

// A mock version of the RefSelector component that simulates
// a scenario where the users has searched for "nonexistent-tag"
// and the component has found no tags that match.
const RefSelectorStub = Vue.component('RefSelectorStub', {
  data() {
    return {
      footerSlotProps: {
        isLoading: false,
        matches: {
          tags: { totalCount: 0 },
        },
        query: NONEXISTENT_TAG_NAME,
      },
    };
  },
  template: '<div><slot name="footer" v-bind="footerSlotProps"></slot></div>',
});

describe('releases/components/tag_field_new', () => {
  let store;
  let wrapper;

  const createComponent = (mountFn = shallowMount) => {
    wrapper = mountFn(TagFieldNew, {
      store,
      stubs: {
        RefSelector: RefSelectorStub,
      },
    });
  };

  beforeEach(() => {
    store = createStore({
      modules: {
        editNew: createEditNewModule({
          projectId: TEST_PROJECT_ID,
        }),
      },
    });

    store.state.editNew.createFrom = TEST_CREATE_FROM;

    store.state.editNew.release = {
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
  const findTagNameDropdown = () => findTagNameFormGroup().find(RefSelectorStub);

  const findCreateFromFormGroup = () => wrapper.find('[data-testid="create-from-field"]');
  const findCreateFromDropdown = () => findCreateFromFormGroup().find(RefSelectorStub);

  const findCreateNewTagOption = () => wrapper.find(GlDropdownItem);

  describe('"Tag name" field', () => {
    describe('rendering and behavior', () => {
      beforeEach(() => createComponent());

      it('renders a label', () => {
        expect(findTagNameFormGroup().attributes().label).toBe('Tag name');
      });

      describe('when the user selects a new tag name', () => {
        beforeEach(async () => {
          findCreateNewTagOption().vm.$emit('click');

          await wrapper.vm.$nextTick();
        });

        it("updates the store's release.tagName property", () => {
          expect(store.state.editNew.release.tagName).toBe(NONEXISTENT_TAG_NAME);
        });

        it('hides the "Create from" field', () => {
          expect(findCreateFromFormGroup().exists()).toBe(true);
        });
      });

      describe('when the user selects an existing tag name', () => {
        const updatedTagName = 'updated-tag-name';

        beforeEach(async () => {
          findTagNameDropdown().vm.$emit('input', updatedTagName);

          await wrapper.vm.$nextTick();
        });

        it("updates the store's release.tagName property", () => {
          expect(store.state.editNew.release.tagName).toBe(updatedTagName);
        });

        it('shows the "Create from" field', () => {
          expect(findCreateFromFormGroup().exists()).toBe(false);
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
      const expectValidationMessageToBe = async (state) => {
        await wrapper.vm.$nextTick();

        expect(findTagNameFormGroup().element).toHaveClass(
          state === 'shown' ? 'is-invalid' : 'is-valid',
        );
        expect(findTagNameFormGroup().element).not.toHaveClass(
          state === 'shown' ? 'is-valid' : 'is-invalid',
        );
      };

      describe('when the user has not yet interacted with the component', () => {
        it('does not display a validation error', async () => {
          findTagNameDropdown().vm.$emit('input', '');

          await expectValidationMessageToBe('hidden');
        });
      });

      describe('when the user has interacted with the component and the value is not empty', () => {
        it('does not display validation error', async () => {
          findTagNameDropdown().vm.$emit('hide');

          await expectValidationMessageToBe('hidden');
        });
      });

      describe('when the user has interacted with the component and the value is empty', () => {
        it('displays a validation error', async () => {
          findTagNameDropdown().vm.$emit('input', '');
          findTagNameDropdown().vm.$emit('hide');

          await expectValidationMessageToBe('shown');
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
      it("updates the store's createFrom property", async () => {
        const updatedCreateFrom = 'update-create-from';
        findCreateFromDropdown().vm.$emit('input', updatedCreateFrom);

        await wrapper.vm.$nextTick();

        expect(store.state.editNew.createFrom).toBe(updatedCreateFrom);
      });
    });
  });
});
