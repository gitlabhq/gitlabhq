import { GlButton, GlModal } from '@gitlab/ui';
import { nextTick } from 'vue';
import { createAlert } from '~/alert';
import Modal from '~/ide/components/new_dropdown/modal.vue';
import { createStore } from '~/ide/stores';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createEntriesFromPaths } from '../../helpers';

jest.mock('~/alert');

const NEW_NAME = 'babar';

describe('new file modal component', () => {
  const showModal = jest.fn();
  const toggleModal = jest.fn();

  let store;
  let wrapper;

  const findForm = () => wrapper.findByTestId('file-name-form');
  const findGlModal = () => wrapper.findComponent(GlModal);
  const findInput = () => wrapper.findByTestId('file-name-field');
  const findTemplateButtons = () => wrapper.findAllComponents(GlButton);
  const findTemplateButtonsModel = () =>
    findTemplateButtons().wrappers.map((x) => ({
      text: x.text(),
      variant: x.props('variant'),
      category: x.props('category'),
    }));

  const open = (type, path) => {
    // TODO: This component can not be passed props
    // We have to interact with the open() method?
    wrapper.vm.open(type, path);
  };
  const triggerSubmitForm = () => {
    findForm().trigger('submit');
  };
  const triggerSubmitModal = () => {
    findGlModal().vm.$emit('primary');
  };
  const triggerCancel = () => {
    findGlModal().vm.$emit('cancel');
  };

  const mountComponent = () => {
    const GlModalStub = stubComponent(GlModal);
    jest.spyOn(GlModalStub.methods, 'show').mockImplementation(showModal);
    jest.spyOn(GlModalStub.methods, 'toggle').mockImplementation(toggleModal);

    wrapper = shallowMountExtended(Modal, {
      store,
      stubs: {
        GlModal: GlModalStub,
      },
      // We need to attach to document for "focus" to work
      attachTo: document.body,
    });
  };

  beforeEach(() => {
    store = createStore();

    Object.assign(
      store.state.entries,
      createEntriesFromPaths([
        'README.md',
        'src',
        'src/deleted.js',
        'src/parent_dir',
        'src/parent_dir/foo.js',
      ]),
    );
    Object.assign(store.state.entries['src/deleted.js'], { deleted: true });

    jest.spyOn(store, 'dispatch').mockImplementation();
  });

  afterEach(() => {
    store = null;
    document.body.innerHTML = '';
  });

  describe('default', () => {
    beforeEach(async () => {
      mountComponent();

      // Not necessarily needed, but used to ensure that nothing extra is happening after the tick
      await nextTick();
    });

    it('renders modal', () => {
      expect(findGlModal().props()).toMatchObject({
        actionCancel: {
          attributes: { variant: 'default' },
          text: 'Cancel',
        },
        actionPrimary: {
          attributes: { variant: 'confirm' },
          text: 'Create file',
        },
        actionSecondary: null,
        size: 'lg',
        modalId: 'ide-new-entry',
        title: 'Create new file',
      });
    });

    it('renders name label', () => {
      expect(wrapper.find('label').text()).toBe('Name');
    });

    it('renders template buttons', () => {
      const actual = findTemplateButtonsModel();

      expect(actual.length).toBeGreaterThan(0);
      expect(actual).toEqual(
        store.getters['fileTemplates/templateTypes'].map((template) => ({
          category: 'secondary',
          text: template.name,
          variant: 'dashed',
        })),
      );
    });

    // These negative ".not.toHaveBeenCalled" assertions complement the positive "toHaveBeenCalled"
    // assertions that show up later in this spec. Without these, we're not guaranteed the "act"
    // actually caused the change in behavior.
    it('does not dispatch actions by default', () => {
      expect(store.dispatch).not.toHaveBeenCalled();
    });

    it('does not trigger modal by default', () => {
      expect(showModal).not.toHaveBeenCalled();
      expect(toggleModal).not.toHaveBeenCalled();
    });

    it('does not focus input by default', () => {
      expect(document.activeElement).toBe(document.body);
    });
  });

  describe.each`
    entryType | path         | modalTitle                | btnTitle              | showsFileTemplates | inputValue    | inputPlaceholder
    ${'tree'} | ${''}        | ${'Create new directory'} | ${'Create directory'} | ${false}           | ${''}         | ${'dir/'}
    ${'blob'} | ${''}        | ${'Create new file'}      | ${'Create file'}      | ${true}            | ${''}         | ${'dir/file_name'}
    ${'blob'} | ${'foo/bar'} | ${'Create new file'}      | ${'Create file'}      | ${true}            | ${'foo/bar/'} | ${'dir/file_name'}
  `(
    'when opened as $entryType with path "$path"',
    ({
      entryType,
      path,
      modalTitle,
      btnTitle,
      showsFileTemplates,
      inputValue,
      inputPlaceholder,
    }) => {
      beforeEach(async () => {
        mountComponent();

        open(entryType, path);

        await nextTick();
      });

      it('sets modal props', () => {
        expect(findGlModal().props()).toMatchObject({
          title: modalTitle,
          actionPrimary: {
            attributes: { variant: 'confirm' },
            text: btnTitle,
          },
        });
      });

      it('sets input attributes', () => {
        expect(findInput().element.value).toBe(inputValue);
        expect(findInput().attributes('placeholder')).toBe(inputPlaceholder);
      });

      it(`shows file templates: ${showsFileTemplates}`, () => {
        const actual = findTemplateButtonsModel().length > 0;

        expect(actual).toBe(showsFileTemplates);
      });

      it('shows modal', () => {
        expect(showModal).toHaveBeenCalled();
      });

      it('focus on input', () => {
        expect(document.activeElement).toBe(findInput().element);
      });

      it('resets when canceled', async () => {
        triggerCancel();

        await nextTick();

        // Resets input value
        expect(findInput().element.value).toBe('');
        // Resets to blob mode
        expect(findGlModal().props('title')).toBe('Create new file');
      });
    },
  );

  describe.each`
    modalType | name             | expectedName
    ${'blob'} | ${'foo/bar.js'}  | ${'foo/bar.js'}
    ${'blob'} | ${'foo /bar.js'} | ${'foo/bar.js'}
    ${'tree'} | ${'foo/dir'}     | ${'foo/dir'}
    ${'tree'} | ${'foo /dir'}    | ${'foo/dir'}
  `('when submitting as $modalType with "$name"', ({ modalType, name, expectedName }) => {
    describe('when using the modal primary button', () => {
      beforeEach(async () => {
        mountComponent();

        open(modalType, '');
        await nextTick();

        findInput().setValue(name);
        triggerSubmitModal();
      });

      it('triggers createTempEntry action', () => {
        expect(store.dispatch).toHaveBeenCalledWith('createTempEntry', {
          name: expectedName,
          type: modalType,
        });
      });
    });

    describe('when triggering form submit (pressing enter)', () => {
      beforeEach(async () => {
        mountComponent();

        open(modalType, '');
        await nextTick();

        findInput().setValue(name);
        triggerSubmitForm();
      });

      it('triggers createTempEntry action', () => {
        expect(store.dispatch).toHaveBeenCalledWith('createTempEntry', {
          name: expectedName,
          type: modalType,
        });
      });
    });
  });

  describe('when creating from template type', () => {
    beforeEach(async () => {
      mountComponent();

      open('blob', 'some_dir');

      await nextTick();

      // Set input, then trigger button
      findInput().setValue('some_dir/foo.js');
      findTemplateButtons().at(1).vm.$emit('click');
    });

    it('triggers createTempEntry action', () => {
      const { name: expectedName } = store.getters['fileTemplates/templateTypes'][1];

      expect(store.dispatch).toHaveBeenCalledWith('createTempEntry', {
        name: `some_dir/${expectedName}`,
        type: 'blob',
      });
    });

    it('toggles modal', () => {
      expect(toggleModal).toHaveBeenCalled();
    });
  });

  describe.each`
    origPath            | title              | inputValue          | inputSelectionStart
    ${'src/parent_dir'} | ${'Rename folder'} | ${'src/parent_dir'} | ${'src/'.length}
    ${'README.md'}      | ${'Rename file'}   | ${'README.md'}      | ${0}
  `('when renaming for $origPath', ({ origPath, title, inputValue, inputSelectionStart }) => {
    beforeEach(async () => {
      mountComponent();

      open('rename', origPath);

      await nextTick();
    });

    it('sets modal props for renaming', () => {
      expect(findGlModal().props()).toMatchObject({
        title,
        actionPrimary: {
          attributes: { variant: 'confirm' },
          text: title,
        },
      });
    });

    it('sets input value', () => {
      expect(findInput().element.value).toBe(inputValue);
    });

    it(`does not show file templates`, () => {
      expect(findTemplateButtonsModel()).toHaveLength(0);
    });

    it('shows modal when renaming', () => {
      expect(showModal).toHaveBeenCalled();
    });

    it('focus on input when renaming', () => {
      expect(document.activeElement).toBe(findInput().element);
    });

    it('selects name part of the input', () => {
      expect(findInput().element.selectionStart).toBe(inputSelectionStart);
      expect(findInput().element.selectionEnd).toBe(origPath.length);
    });

    describe('when renames is submitted successfully', () => {
      describe('when using the modal primary button', () => {
        beforeEach(() => {
          findInput().setValue(NEW_NAME);
          triggerSubmitModal();
        });

        it('dispatches renameEntry event', () => {
          expect(store.dispatch).toHaveBeenCalledWith('renameEntry', {
            path: origPath,
            parentPath: '',
            name: NEW_NAME,
          });
        });

        it('does not trigger alert', () => {
          expect(createAlert).not.toHaveBeenCalled();
        });
      });

      describe('when triggering form submit (pressing enter)', () => {
        beforeEach(() => {
          findInput().setValue(NEW_NAME);
          triggerSubmitForm();
        });

        it('dispatches renameEntry event', () => {
          expect(store.dispatch).toHaveBeenCalledWith('renameEntry', {
            path: origPath,
            parentPath: '',
            name: NEW_NAME,
          });
        });

        it('does not trigger alert', () => {
          expect(createAlert).not.toHaveBeenCalled();
        });
      });
    });
  });

  describe('when renaming and file already exists', () => {
    beforeEach(async () => {
      mountComponent();

      open('rename', 'src/parent_dir');

      await nextTick();

      // Set to something that already exists!
      findInput().setValue('src');
      triggerSubmitModal();
    });

    it('creates alert', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: 'The name "src" is already taken in this directory.',
        fadeTransition: false,
        addBodyClass: true,
      });
    });

    it('does not dispatch event', () => {
      expect(store.dispatch).not.toHaveBeenCalled();
    });
  });

  describe('when renaming and file has been deleted', () => {
    beforeEach(async () => {
      mountComponent();

      open('rename', 'src/parent_dir/foo.js');

      await nextTick();

      findInput().setValue('src/deleted.js');
      triggerSubmitModal();
    });

    it('does not create alert', () => {
      expect(createAlert).not.toHaveBeenCalled();
    });

    it('dispatches event', () => {
      expect(store.dispatch).toHaveBeenCalledWith('renameEntry', {
        path: 'src/parent_dir/foo.js',
        name: 'deleted.js',
        parentPath: 'src',
      });
    });
  });
});
