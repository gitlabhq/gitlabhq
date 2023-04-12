import { GlCollapsibleListbox } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
import NamespaceSelect from '~/pages/admin/projects/components/namespace_select.vue';

const TEST_USER_NAMESPACE = { id: 10, kind: 'user', full_path: 'Administrator' };
const TEST_GROUP_NAMESPACE = { id: 20, kind: 'group', full_path: 'GitLab Org' };

describe('NamespaceSelect', () => {
  let wrapper;

  const createComponent = (propsData) => {
    wrapper = shallowMountExtended(NamespaceSelect, { propsData });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findNamespaceInput = () => wrapper.findByTestId('hidden-input');

  const search = async (searchString) => {
    findListbox().vm.$emit('search', searchString);
    await waitForPromises();
  };

  beforeEach(() => {
    setHTMLFixture('<div class="test-container"></div>');

    jest
      .spyOn(Api, 'namespaces')
      .mockImplementation((_, callback) => callback([TEST_USER_NAMESPACE, TEST_GROUP_NAMESPACE]));
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('on mount', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not show hidden input', () => {
      expect(findNamespaceInput().exists()).toBe(false);
    });

    it('sets appropriate props', () => {
      expect(findListbox().props()).toMatchObject({
        items: [
          { text: 'user: Administrator', value: '10' },
          { text: 'group: GitLab Org', value: '20' },
        ],
        headerText: NamespaceSelect.i18n.headerText,
        resetButtonLabel: NamespaceSelect.i18n.reset,
        toggleText: 'Namespace',
        searchPlaceholder: NamespaceSelect.i18n.searchPlaceholder,
        searching: false,
        searchable: true,
      });
    });
  });

  it('with fieldName, shows hidden input', () => {
    createComponent({ fieldName: 'namespace-input' });

    expect(findNamespaceInput().exists()).toBe(true);
    expect(findNamespaceInput().attributes('name')).toBe('namespace-input');
  });

  describe('select', () => {
    describe.each`
      selectId                           | expectToggleText
      ${String(TEST_USER_NAMESPACE.id)}  | ${`user: ${TEST_USER_NAMESPACE.full_path}`}
      ${String(TEST_GROUP_NAMESPACE.id)} | ${`group: ${TEST_GROUP_NAMESPACE.full_path}`}
    `('clicking listbox options (selectId=$selectId)', ({ selectId, expectToggleText }) => {
      beforeEach(async () => {
        createComponent({ fieldName: 'namespace-input' });
        findListbox().vm.$emit('select', selectId);
        await nextTick();
      });

      it('updates hidden field', () => {
        expect(findNamespaceInput().attributes('value')).toBe(selectId);
      });

      it('updates the listbox value', () => {
        expect(findListbox().props()).toMatchObject({
          selected: selectId,
          toggleText: expectToggleText,
        });
      });

      it('triggers a setNamespace event upon selection', () => {
        expect(wrapper.emitted('setNamespace')).toEqual([[selectId]]);
      });
    });
  });

  describe('search', () => {
    it('retrieves namespaces based on filter query', async () => {
      createComponent();

      // Add space to assert that `?.trim` is called
      await search('test ');

      expect(Api.namespaces).toHaveBeenCalledWith('test', expect.anything());
    });

    it('when not found, does not change the placeholder text', async () => {
      createComponent({
        origSelectedId: String(TEST_USER_NAMESPACE.id),
        origSelectedText: `user: ${TEST_USER_NAMESPACE.full_path}`,
      });

      await search('not exist');

      expect(findListbox().props()).toMatchObject({
        selected: String(TEST_USER_NAMESPACE.id),
        toggleText: `user: ${TEST_USER_NAMESPACE.full_path}`,
      });
    });
  });

  describe('reset', () => {
    beforeEach(() => {
      createComponent();
      findListbox().vm.$emit('reset');
    });

    it('updates the listbox value', () => {
      expect(findListbox().props()).toMatchObject({
        selected: null,
        toggleText: 'Namespace',
      });
    });

    it('triggers a setNamespace event upon reset', () => {
      expect(wrapper.emitted('setNamespace')).toEqual([[null]]);
    });
  });
});
