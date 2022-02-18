import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Api from '~/api';
import NamespaceSelect from '~/pages/admin/projects/components/namespace_select.vue';

describe('Dropdown select component', () => {
  let wrapper;

  const mountDropdown = (propsData) => {
    wrapper = mount(NamespaceSelect, { propsData });
  };

  const findDropdownToggle = () => wrapper.find('button.dropdown-toggle');
  const findNamespaceInput = () => wrapper.find('[data-testid="hidden-input"]');
  const findFilterInput = () => wrapper.find('.namespace-search-box input');
  const findDropdownOption = (match) => {
    const buttons = wrapper
      .findAll('button.dropdown-item')
      .filter((node) => node.text().match(match));
    return buttons.length ? buttons.at(0) : buttons;
  };

  const setFieldValue = async (field, value) => {
    await field.setValue(value);
    field.trigger('blur');
  };

  beforeEach(() => {
    setFixtures('<div class="test-container"></div>');

    jest.spyOn(Api, 'namespaces').mockImplementation((_, callback) =>
      callback([
        { id: 10, kind: 'user', full_path: 'Administrator' },
        { id: 20, kind: 'group', full_path: 'GitLab Org' },
      ]),
    );
  });

  it('creates a hidden input if fieldName is provided', () => {
    mountDropdown({ fieldName: 'namespace-input' });

    expect(findNamespaceInput().exists()).toBe(true);
    expect(findNamespaceInput().attributes('name')).toBe('namespace-input');
  });

  describe('clicking dropdown options', () => {
    it('retrieves namespaces based on filter query', async () => {
      mountDropdown();

      await setFieldValue(findFilterInput(), 'test');

      expect(Api.namespaces).toHaveBeenCalledWith('test', expect.anything());
    });

    it('updates the dropdown value based upon selection', async () => {
      mountDropdown({ fieldName: 'namespace-input' });

      // wait for dropdown options to populate
      await nextTick();

      expect(findDropdownOption('user: Administrator').exists()).toBe(true);
      expect(findDropdownOption('group: GitLab Org').exists()).toBe(true);
      expect(findDropdownOption('group: Foobar').exists()).toBe(false);

      findDropdownOption('user: Administrator').trigger('click');
      await nextTick();

      expect(findNamespaceInput().attributes('value')).toBe('10');
      expect(findDropdownToggle().text()).toBe('user: Administrator');
    });

    it('triggers a setNamespace event upon selection', async () => {
      mountDropdown();

      // wait for dropdown options to populate
      await nextTick();

      findDropdownOption('group: GitLab Org').trigger('click');

      expect(wrapper.emitted('setNamespace')).toHaveLength(1);
      expect(wrapper.emitted('setNamespace')[0][0]).toBe(20);
    });

    it('displays "Any Namespace" option when showAny prop provided', () => {
      mountDropdown({ showAny: true });
      expect(wrapper.text()).toContain('Any namespace');
    });

    it('does not display "Any Namespace" option when showAny prop not provided', () => {
      mountDropdown();
      expect(wrapper.text()).not.toContain('Any namespace');
    });
  });
});
