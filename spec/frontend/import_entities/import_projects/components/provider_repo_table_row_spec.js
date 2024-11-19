import { GlBadge, GlButton } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import { STATUSES } from '~/import_entities/constants';
import ImportTargetDropdown from '~/import_entities/components/import_target_dropdown.vue';
import ImportStatus from '~/import_entities/components/import_status.vue';
import ProviderRepoTableRow from '~/import_entities/import_projects/components/provider_repo_table_row.vue';

describe('ProviderRepoTableRow', () => {
  let wrapper;
  const fetchImport = jest.fn();
  const cancelImport = jest.fn();
  const setImportTarget = jest.fn();
  const groupImportTarget = {
    targetNamespace: 'target',
    newName: 'newName',
  };

  const userNamespace = 'root';

  function initStore({ importTarget = groupImportTarget } = {}) {
    const store = new Vuex.Store({
      state: {},
      getters: {
        getImportTarget: () => () => importTarget,
      },
      actions: { fetchImport, cancelImport, setImportTarget },
    });

    return store;
  }

  const findButton = (text) => {
    const buttons = wrapper.findAllComponents(GlButton).filter((node) => node.text() === text);

    return buttons.length ? buttons.at(0) : buttons;
  };

  const findImportButton = () => findButton('Import');
  const findReimportButton = () => findButton('Re-import');
  const findImportTargetDropdown = () => wrapper.findComponent(ImportTargetDropdown);
  const findImportStatus = () => wrapper.findComponent(ImportStatus);
  const findProviderLink = () => wrapper.findByTestId('provider-link');
  const findMembershipsWarning = () => wrapper.findByTestId('memberships-warning');

  const findCancelButton = () => {
    const buttons = wrapper
      .findAllComponents(GlButton)
      .filter((node) => node.attributes('aria-label') === 'Cancel');

    return buttons.length ? buttons.at(0) : buttons;
  };

  function mountComponent(props, { storeOptions = {} } = {}) {
    Vue.use(Vuex);

    const store = initStore(storeOptions);

    wrapper = shallowMountExtended(ProviderRepoTableRow, {
      store,
      propsData: { optionalStages: {}, ...props },
      provide: {
        userNamespace,
      },
    });
  }

  describe('when rendering importable project', () => {
    const repo = {
      importSource: {
        id: 'remote-1',
        fullName: 'fullName',
        providerLink: 'providerLink',
      },
    };

    beforeEach(() => {
      mountComponent({ repo });
    });

    it('renders project information', () => {
      const providerLink = findProviderLink();

      expect(providerLink.attributes().href).toMatch(repo.importSource.providerLink);
      expect(providerLink.text()).toMatch(repo.importSource.fullName);
    });

    it('renders empty import status', () => {
      expect(findImportStatus().props().status).toBe(STATUSES.NONE);
    });

    it('renders a group namespace select', () => {
      expect(findImportTargetDropdown().exists()).toBe(true);
    });

    describe('when user namespace is selected as import target', () => {
      beforeEach(() => {
        mountComponent(
          { repo },
          { storeOptions: { importTarget: { targetNamespace: userNamespace } } },
        );
      });

      it('shows memberships warning', () => {
        expect(findMembershipsWarning().isVisible()).toBe(true);
      });
    });

    describe('when group namespace is selected as import target', () => {
      it('does not show memberships warning', () => {
        expect(findMembershipsWarning().isVisible()).toBe(false);
      });
    });

    it('renders import button', () => {
      expect(findImportButton().exists()).toBe(true);
    });

    it('imports repo when clicking import button', async () => {
      findImportButton().vm.$emit('click');

      await nextTick();

      expect(fetchImport).toHaveBeenCalledWith(expect.anything(), {
        repoId: repo.importSource.id,
        optionalStages: {},
      });
    });

    it('includes optionalStages to import', async () => {
      const OPTIONAL_STAGES = { stage1: true, stage2: false };

      mountComponent({
        repo,
        optionalStages: OPTIONAL_STAGES,
      });

      findImportButton().vm.$emit('click');

      await nextTick();

      expect(fetchImport).toHaveBeenCalledWith(expect.anything(), {
        repoId: repo.importSource.id,
        optionalStages: OPTIONAL_STAGES,
      });
    });

    it('does not render re-import button', () => {
      expect(findReimportButton().exists()).toBe(false);
    });
  });

  describe('when rendering importing project', () => {
    const repo = {
      importSource: {
        id: 'remote-1',
        fullName: 'fullName',
        providerLink: 'providerLink',
      },
      importedProject: {
        id: 1,
        fullPath: 'fullPath',
        importSource: 'importSource',
        importStatus: STATUSES.STARTED,
      },
    };

    describe('when cancelable is true', () => {
      beforeEach(() => {
        mountComponent({ repo, cancelable: true });
      });

      it('shows cancel button', () => {
        expect(findCancelButton().isVisible()).toBe(true);
      });

      it('cancels import when clicking cancel button', async () => {
        findCancelButton().vm.$emit('click');

        await nextTick();

        expect(cancelImport).toHaveBeenCalledWith(expect.anything(), {
          repoId: repo.importSource.id,
        });
      });
    });

    describe('when cancelable is false', () => {
      beforeEach(() => {
        mountComponent({ repo, cancelable: false });
      });

      it('hides cancel button', () => {
        expect(findCancelButton().isVisible()).toBe(false);
      });
    });
  });

  describe('when rendering imported project', () => {
    const FAKE_STATS = {};

    const repo = {
      importSource: {
        id: 'remote-1',
        fullName: 'fullName',
        providerLink: 'providerLink',
      },
      importedProject: {
        id: 1,
        fullPath: 'fullPath',
        importSource: 'importSource',
        importStatus: STATUSES.FINISHED,
        stats: FAKE_STATS,
      },
    };

    beforeEach(() => {
      mountComponent({ repo });
    });

    it('renders project information', () => {
      const providerLink = findProviderLink();

      expect(providerLink.attributes().href).toMatch(repo.importSource.providerLink);
      expect(providerLink.text()).toMatch(repo.importSource.fullName);
    });

    it('renders proper import status', () => {
      expect(findImportStatus().props().status).toBe(repo.importedProject.importStatus);
    });

    it('does not render a namespace select', () => {
      expect(findImportTargetDropdown().exists()).toBe(false);
    });

    it('does not render import button', () => {
      expect(findImportButton().exists()).toBe(false);
    });

    it('renders re-import button', () => {
      expect(findReimportButton().exists()).toBe(true);
    });

    it('renders namespace select after clicking re-import', async () => {
      findReimportButton().vm.$emit('click');

      await nextTick();

      expect(findImportTargetDropdown().exists()).toBe(true);
    });

    it('imports repo when clicking re-import button', async () => {
      findReimportButton().vm.$emit('click');

      await nextTick();

      findReimportButton().vm.$emit('click');

      expect(fetchImport).toHaveBeenCalledWith(expect.anything(), {
        repoId: repo.importSource.id,
        optionalStages: {},
      });
    });

    it('passes props to import status component', () => {
      expect(findImportStatus().props()).toMatchObject({
        projectId: repo.importedProject.id,
        stats: FAKE_STATS,
      });
    });
  });

  describe('when rendering failed project', () => {
    const repo = {
      importSource: {
        id: 'remote-1',
        fullName: 'fullName',
        providerLink: 'providerLink',
      },
      importedProject: {
        id: 1,
        fullPath: 'fullPath',
        importSource: 'importSource',
        importStatus: STATUSES.FAILED,
      },
    };

    beforeEach(() => {
      mountComponent({ repo });
    });

    it('render import button', () => {
      expect(findImportButton().exists()).toBe(true);
    });
  });

  describe('when rendering incompatible project', () => {
    const repo = {
      importSource: {
        id: 'remote-1',
        fullName: 'fullName',
        providerLink: 'providerLink',
        incompatible: true,
      },
    };

    beforeEach(() => {
      mountComponent({ repo });
    });

    it('renders project information', () => {
      const providerLink = findProviderLink();

      expect(providerLink.attributes().href).toMatch(repo.importSource.providerLink);
      expect(providerLink.text()).toMatch(repo.importSource.fullName);
    });

    it('renders badge with error', () => {
      expect(wrapper.findComponent(GlBadge).text()).toBe('Incompatible project');
    });
  });
});
