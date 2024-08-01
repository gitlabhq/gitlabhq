import { GlFormGroup, GlTruncate, GlPopover } from '@gitlab/ui';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TagFieldNew from '~/releases/components/tag_field_new.vue';
import TagSearch from '~/releases/components/tag_search.vue';
import TagCreate from '~/releases/components/tag_create.vue';
import createStore from '~/releases/stores';
import createEditNewModule from '~/releases/stores/modules/edit_new';
import { CREATE } from '~/releases/stores/modules/edit_new/constants';
import { createRefModule } from '~/ref/stores';
import { i18n } from '~/releases/constants';

const TEST_TAG_NAME = 'test-tag-name';
const TEST_PROJECT_ID = '1234';
const TEST_CREATE_FROM = 'test-create-from';
const NONEXISTENT_TAG_NAME = 'nonexistent-tag';

describe('releases/components/tag_field_new', () => {
  let store;
  let wrapper;
  let mock;

  const createComponent = () => {
    wrapper = shallowMountExtended(TagFieldNew, {
      store,
      stubs: {
        GlFormGroup,
      },
    });
  };

  beforeEach(() => {
    store = createStore({
      modules: {
        editNew: createEditNewModule({
          projectId: TEST_PROJECT_ID,
        }),
        ref: createRefModule(),
      },
    });

    store.state.editNew.createFrom = TEST_CREATE_FROM;
    store.state.editNew.step = CREATE;

    store.state.editNew.release = {
      tagName: TEST_TAG_NAME,
      tagMessage: '',
      assets: {
        links: [],
      },
    };

    mock = new MockAdapter(axios);
    gon.api_version = 'v4';
  });

  afterEach(() => mock.restore());

  const findTagNameFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findTagNameInputText = () => wrapper.findComponent(GlTruncate);
  const findTagNamePopover = () => wrapper.findComponent(GlPopover);
  const findTagNameSearch = () => wrapper.findComponent(TagSearch);
  const findTagNameCreate = () => wrapper.findComponent(TagCreate);

  describe('"Tag name" field', () => {
    describe('rendering and behavior', () => {
      beforeEach(() => createComponent());

      it('renders a label', () => {
        expect(findTagNameFormGroup().attributes().label).toBe('Tag name');
        expect(findTagNameFormGroup().props().optionalText).toBe('(required)');
      });

      it('flips between search and create, passing the searched value', async () => {
        let create = findTagNameCreate();
        let search = findTagNameSearch();

        expect(create.exists()).toBe(true);
        expect(search.exists()).toBe(false);

        await create.vm.$emit('cancel');

        search = findTagNameSearch();
        expect(create.exists()).toBe(false);
        expect(search.exists()).toBe(true);

        await search.vm.$emit('create', TEST_TAG_NAME);

        create = findTagNameCreate();
        expect(create.exists()).toBe(true);
        expect(create.props('value')).toBe(TEST_TAG_NAME);
        expect(search.exists()).toBe(false);
      });

      describe('when the user selects a new tag name', () => {
        it("updates the store's release.tagName property", async () => {
          findTagNameCreate().vm.$emit('change', NONEXISTENT_TAG_NAME);
          await findTagNameCreate().vm.$emit('create');
          expect(store.state.editNew.release.tagName).toBe(NONEXISTENT_TAG_NAME);

          const text = findTagNameInputText();
          expect(text.props('text')).toBe(NONEXISTENT_TAG_NAME);
        });
      });

      describe('when the user selects an existing tag name', () => {
        const updatedTagName = 'updated-tag-name';

        beforeEach(async () => {
          await findTagNameCreate().vm.$emit('cancel');
          findTagNameSearch().vm.$emit('select', updatedTagName);
        });

        it("updates the store's release.tagName property", () => {
          const buttonText = findTagNameInputText();
          expect(store.state.editNew.release.tagName).toBe(updatedTagName);

          expect(buttonText.props('text')).toBe(updatedTagName);
        });

        it('hides the "Create from" field', () => {
          expect(findTagNameCreate().exists()).toBe(false);
        });

        it('fetches the release notes for the tag', () => {
          const expectedUrl = `/api/v4/projects/1234/repository/tags/${updatedTagName}`;
          expect(mock.history.get).toContainEqual(expect.objectContaining({ url: expectedUrl }));
        });
      });
    });

    describe('validation', () => {
      beforeEach(() => {
        createComponent();
        findTagNameCreate().vm.$emit('cancel');
      });

      /**
       * Utility function to test the visibility of the validation message
       * @param {boolean} isShown Whether or not the message is shown.
       */
      const expectValidationMessageToBeShown = async (isShown) => {
        await nextTick();

        const state = findTagNameFormGroup().attributes('state');

        if (isShown) {
          expect(state).toBeUndefined();
        } else {
          expect(state).toBe('true');
        }
      };

      describe('when the user has not yet interacted with the component', () => {
        it('does not display a validation error', async () => {
          await expectValidationMessageToBeShown(false);
        });
      });

      describe('when the user has interacted with the component and the value is not empty', () => {
        it('does not display validation error', async () => {
          findTagNameSearch().vm.$emit('select', 'vTest');
          findTagNamePopover().vm.$emit('hide');

          await expectValidationMessageToBeShown(false);
        });

        it('displays a validation error if the tag has an associated release', async () => {
          findTagNameSearch().vm.$emit('select', 'vTest');
          findTagNamePopover().vm.$emit('hide');

          store.state.editNew.existingRelease = {};

          await expectValidationMessageToBeShown(true);
          expect(findTagNameFormGroup().attributes('invalidfeedback')).toBe(
            i18n.tagIsAlredyInUseMessage,
          );
        });
      });

      describe('when the user has interacted with the component and the value is empty', () => {
        it('displays a validation error', async () => {
          findTagNameSearch().vm.$emit('select', '');
          findTagNamePopover().vm.$emit('hide');

          await expectValidationMessageToBeShown(true);
          expect(findTagNameFormGroup().attributes('invalidfeedback')).toContain(
            i18n.tagNameIsRequiredMessage,
          );
        });
      });
    });
  });
});
