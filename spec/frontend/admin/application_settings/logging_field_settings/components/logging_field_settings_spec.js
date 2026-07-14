import { GlAlert, GlBadge, GlFormSelect, GlTableLite } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert, VARIANT_INFO } from '~/alert';
import LoggingFieldSettings from '~/admin/application_settings/logging_field_settings/components/logging_field_settings.vue';

jest.mock('~/alert');

const AVAILABLE_VERSIONS = [0, 1, 2];
const LATEST_VERSION = 2;
const FIELD_CHANGES = {
  1: [
    { standard_field: 'correlation_id', deprecated_fields: ['tags.correlation_id'] },
    { standard_field: 'gl_user_id', deprecated_fields: ['user_id', 'userid'] },
  ],
  2: [{ standard_field: 'duration_s', deprecated_fields: ['duration_ms'] }],
};

describe('LoggingFieldSettings', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(LoggingFieldSettings, {
      propsData: {
        persistedVersion: 0,
        latestVersion: LATEST_VERSION,
        availableVersions: AVAILABLE_VERSIONS,
        fieldChanges: FIELD_CHANGES,
        ...props,
      },
      stubs: { GlTableLite },
    });
  };

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findAllSelects = () => wrapper.findAllComponents(GlFormSelect);
  const findSchemaSelect = () => findAllSelects().at(0);
  const findDualEmitSelect = () => findAllSelects().at(1);
  const findHelp = () => wrapper.findByTestId('field-changes-help');
  const findTable = () => wrapper.findComponent(GlTableLite);
  const findWarning = () => wrapper.findByTestId('dual-emit-warning');

  const setSchemaVersion = async (value) => {
    findSchemaSelect().vm.$emit('input', value);
    await nextTick();
  };

  const setDualEmitTarget = async (value) => {
    findDualEmitSelect().vm.$emit('input', value);
    await nextTick();
  };

  afterEach(() => {
    createAlert.mockReset();
  });

  describe('rendering', () => {
    it('renders the persisted-version badge', () => {
      createComponent({ persistedVersion: 1 });

      expect(findBadge().text()).toBe('v1');
    });

    it('labels the latest version with "(latest)"', () => {
      createComponent({ persistedVersion: LATEST_VERSION });

      expect(findBadge().text()).toBe('v2 (latest)');
    });

    it('renders the dual-emit cost warning', () => {
      createComponent();

      expect(findWarning().exists()).toBe(true);
      expect(findWarning().attributes('variant')).toBe('warning');
    });
  });

  describe('schema-version select', () => {
    it('disables options below the persisted version', () => {
      createComponent({ persistedVersion: 1 });

      expect(wrapper.vm.schemaOptions).toEqual([
        { value: 0, text: 'v0', disabled: true },
        { value: 1, text: 'v1', disabled: false },
        { value: 2, text: 'v2 (latest)', disabled: false },
      ]);
    });
  });

  describe('dual-emit select', () => {
    it('filters options to versions strictly greater than the schema version', () => {
      createComponent({ persistedVersion: 0 });

      expect(wrapper.vm.dualEmitOptions.map((o) => o.value)).toEqual(['', 1, 2]);
    });

    it('disables the dual-emit select when schemaVersion equals latestVersion', () => {
      createComponent({ persistedVersion: LATEST_VERSION });

      expect(findDualEmitSelect().attributes('disabled')).toBeDefined();
    });

    it('emits an info alert when the user moves to the latest version', async () => {
      createComponent({ persistedVersion: 0 });

      await setSchemaVersion(LATEST_VERSION);

      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          variant: VARIANT_INFO,
          message: expect.stringContaining('latest available version'),
        }),
      );
    });

    it('clears an in-flight dual-emit target when schema version catches up to it', async () => {
      createComponent({ persistedVersion: 0 });

      await setDualEmitTarget(1);
      expect(findDualEmitSelect().attributes('value')).toBe('1');

      await setSchemaVersion(1);
      expect(findDualEmitSelect().attributes('value')).toBe('');
    });
  });

  describe('field-changes help', () => {
    it('is hidden on v0 with no dual-emit target', () => {
      createComponent({ persistedVersion: 0 });

      expect(findHelp().exists()).toBe(false);
    });

    it('shows the upgrade variant when schema version is bumped', async () => {
      createComponent({ persistedVersion: 0 });

      await setSchemaVersion(1);

      expect(findHelp().exists()).toBe(true);
      expect(findHelp().text()).toContain('When upgrading to v1');

      const table = findTable();
      expect(table.exists()).toBe(true);
      expect(table.props('fields').map((f) => f.label)).toEqual(
        expect.arrayContaining([expect.stringContaining('Replaces')]),
      );
      expect(table.props('items')).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            standard_field: 'correlation_id',
            deprecated_fields: expect.arrayContaining(['tags.correlation_id']),
          }),
        ]),
      );
    });

    it('shows the dual-emit variant when a dual-emit target is selected', async () => {
      createComponent({ persistedVersion: 0 });

      await setDualEmitTarget(1);

      expect(findHelp().exists()).toBe(true);
      expect(findHelp().text()).toContain('When dual-emitting v1');

      const table = findTable();
      expect(table.props('fields').map((f) => f.label)).toEqual(
        expect.arrayContaining([expect.stringContaining('Also emitted as')]),
      );
    });
  });

  describe('form integration', () => {
    const findHiddenInputs = () => wrapper.findAll('input[type="hidden"]');
    const findHiddenInputByName = (name) =>
      findHiddenInputs().wrappers.find((w) => w.attributes('name') === name);

    it('submits the schema version via a hidden input', async () => {
      createComponent({ persistedVersion: 0 });

      await setSchemaVersion(1);

      const input = findHiddenInputByName('application_setting[logging_field_schema_version]');
      expect(input.attributes('value')).toBe('1');
    });

    it('submits the dual-emit target via a hidden input', async () => {
      createComponent({ persistedVersion: 0 });

      await setDualEmitTarget(1);

      const input = findHiddenInputByName('application_setting[logging_field_dual_emit_target]');
      expect(input.attributes('value')).toBe('1');
    });

    it('initializes the dual-emit hidden input from persistedDualEmitTarget', () => {
      createComponent({ persistedVersion: 0, persistedDualEmitTarget: 2 });

      const input = findHiddenInputByName('application_setting[logging_field_dual_emit_target]');
      expect(input.attributes('value')).toBe('2');
    });

    it('submits an empty string when no dual-emit target is selected', () => {
      createComponent({ persistedVersion: 0, persistedDualEmitTarget: null });

      const input = findHiddenInputByName('application_setting[logging_field_dual_emit_target]');
      expect(input.element.value).toBe('');
    });

    // The backend relies on this invariant: even with the dual-emit select disabled
    // (schema version is at the latest), both hidden inputs must still submit so the
    // controller never has to special-case missing params.
    it('submits both hidden inputs when at the latest version', () => {
      createComponent({ persistedVersion: LATEST_VERSION, persistedDualEmitTarget: null });

      expect(findDualEmitSelect().attributes('disabled')).toBeDefined();
      expect(
        findHiddenInputByName('application_setting[logging_field_schema_version]').exists(),
      ).toBe(true);
      expect(
        findHiddenInputByName('application_setting[logging_field_dual_emit_target]').exists(),
      ).toBe(true);
    });

    it('only renders the dual-emit cost warning by default', () => {
      createComponent();

      expect(wrapper.findAllComponents(GlAlert)).toHaveLength(1);
    });
  });
});
