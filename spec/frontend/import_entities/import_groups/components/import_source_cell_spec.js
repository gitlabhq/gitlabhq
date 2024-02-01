import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { STATUSES } from '~/import_entities/constants';
import ImportSourceCell from '~/import_entities/import_groups/components/import_source_cell.vue';
import { generateFakeEntry } from '../graphql/fixtures';

const generateFakeTableEntry = ({ flags = {}, ...entry }) => ({
  ...generateFakeEntry(entry),
  flags,
});

describe('import source cell', () => {
  let wrapper;
  let group;

  const createComponent = (props) => {
    wrapper = shallowMount(ImportSourceCell, {
      propsData: {
        ...props,
      },
      stubs: { GlSprintf },
    });
  };

  describe('when group status is NONE', () => {
    beforeEach(() => {
      group = generateFakeTableEntry({ id: 1, status: STATUSES.NONE });
      createComponent({ group });
    });

    it('renders link to a group', () => {
      const link = wrapper.findComponent(GlLink);
      expect(link.attributes().href).toBe(group.webUrl);
      expect(link.text()).toContain(group.fullPath);
    });

    it('does not render last imported line', () => {
      expect(wrapper.text()).not.toContain('Last imported to');
    });
  });

  describe('when group status is FINISHED', () => {
    beforeEach(() => {
      group = generateFakeTableEntry({
        id: 1,
        status: STATUSES.FINISHED,
        flags: {
          isFinished: true,
        },
      });
      createComponent({ group });
    });

    it('renders link to a group', () => {
      const link = wrapper.findComponent(GlLink);
      expect(link.attributes().href).toBe(group.webUrl);
      expect(link.text()).toContain(group.fullPath);
    });

    it('renders last imported line', () => {
      expect(wrapper.text()).toContain('fake_group_1');
      expect(wrapper.text()).toContain('Last imported to Commit451/group1');
    });
  });
});
