import { GlButton, GlDropdownItem, GlLink, GlFormInput } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import ImportGroupDropdown from '~/import_entities/components/group_dropdown.vue';
import { STATUSES } from '~/import_entities/constants';
import ImportTargetCell from '~/import_entities/import_groups/components/import_target_cell.vue';
import { availableNamespacesFixture } from '../graphql/fixtures';

Vue.use(VueApollo);

const getFakeGroup = (status) => ({
  web_url: 'https://fake.host/',
  full_path: 'fake_group_1',
  full_name: 'fake_name_1',
  import_target: {
    target_namespace: 'root',
    new_name: 'group1',
  },
  id: 1,
  validation_errors: [],
  progress: { status },
});

describe('import target cell', () => {
  let wrapper;
  let group;

  const findByText = (cmp, text) => {
    return wrapper.findAll(cmp).wrappers.find((node) => node.text().indexOf(text) === 0);
  };
  const findNameInput = () => wrapper.find(GlFormInput);
  const findNamespaceDropdown = () => wrapper.find(ImportGroupDropdown);

  const createComponent = (props) => {
    wrapper = shallowMount(ImportTargetCell, {
      stubs: { ImportGroupDropdown },
      propsData: {
        availableNamespaces: availableNamespacesFixture,
        groupPathRegex: /.*/,
        groupUrlErrorMessage: 'Please choose a group URL with no special characters or spaces.',
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('events', () => {
    beforeEach(() => {
      group = getFakeGroup(STATUSES.NONE);
      createComponent({ group });
    });

    it('invokes $event', () => {
      findNameInput().vm.$emit('input', 'demo');
      expect(wrapper.emitted('update-new-name')).toBeDefined();
      expect(wrapper.emitted('update-new-name')[0][0]).toBe('demo');
    });

    it('emits update-target-namespace when dropdown option is clicked', () => {
      const dropdownItem = findNamespaceDropdown().findAllComponents(GlDropdownItem).at(2);
      const dropdownItemText = dropdownItem.text();

      dropdownItem.vm.$emit('click');

      expect(wrapper.emitted('update-target-namespace')).toBeDefined();
      expect(wrapper.emitted('update-target-namespace')[0][0]).toBe(dropdownItemText);
    });
  });

  describe('when entity status is NONE', () => {
    beforeEach(() => {
      group = getFakeGroup(STATUSES.NONE);
      createComponent({ group });
    });

    it('renders namespace dropdown as not disabled', () => {
      expect(findNamespaceDropdown().attributes('disabled')).toBe(undefined);
    });
  });

  it('renders only no parent option if available namespaces list is empty', () => {
    createComponent({
      group: getFakeGroup(STATUSES.NONE),
      availableNamespaces: [],
    });

    const items = findNamespaceDropdown()
      .findAllComponents(GlDropdownItem)
      .wrappers.map((w) => w.text());

    expect(items[0]).toBe('No parent');
    expect(items).toHaveLength(1);
  });

  it('renders both no parent option and available namespaces list when available namespaces list is not empty', () => {
    createComponent({
      group: getFakeGroup(STATUSES.NONE),
      availableNamespaces: availableNamespacesFixture,
    });

    const [firstItem, ...rest] = findNamespaceDropdown()
      .findAllComponents(GlDropdownItem)
      .wrappers.map((w) => w.text());

    expect(firstItem).toBe('No parent');
    expect(rest).toHaveLength(availableNamespacesFixture.length);
  });

  describe('when entity status is SCHEDULING', () => {
    beforeEach(() => {
      group = getFakeGroup(STATUSES.SCHEDULING);
      createComponent({ group });
    });

    it('does not render Import button', () => {
      expect(findByText(GlButton, 'Import')).toBe(undefined);
    });

    it('renders namespace dropdown as disabled', () => {
      expect(findNamespaceDropdown().attributes('disabled')).toBe('true');
    });
  });

  describe('when entity status is FINISHED', () => {
    beforeEach(() => {
      group = getFakeGroup(STATUSES.FINISHED);
      createComponent({ group });
    });

    it('does not render Import button', () => {
      expect(findByText(GlButton, 'Import')).toBe(undefined);
    });

    it('does not render namespace dropdown', () => {
      expect(findNamespaceDropdown().exists()).toBe(false);
    });

    it('renders target as link', () => {
      const TARGET_LINK = `${group.import_target.target_namespace}/${group.import_target.new_name}`;
      expect(findByText(GlLink, TARGET_LINK).exists()).toBe(true);
    });
  });

  describe('validations', () => {
    it('reports invalid group name when name is not matching regex', () => {
      createComponent({
        group: {
          ...getFakeGroup(STATUSES.NONE),
          import_target: {
            target_namespace: 'root',
            new_name: 'very`bad`name',
          },
        },
        groupPathRegex: /^[a-zA-Z]+$/,
      });

      expect(wrapper.text()).toContain(
        'Please choose a group URL with no special characters or spaces.',
      );
    });

    it('reports invalid group name if relevant validation error exists', async () => {
      const FAKE_ERROR_MESSAGE = 'fake error';

      createComponent({
        group: {
          ...getFakeGroup(STATUSES.NONE),
          validation_errors: [
            {
              field: 'new_name',
              message: FAKE_ERROR_MESSAGE,
            },
          ],
        },
      });

      jest.runOnlyPendingTimers();
      await nextTick();

      expect(wrapper.text()).toContain(FAKE_ERROR_MESSAGE);
    });
  });
});
