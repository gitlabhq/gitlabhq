import DiagnosticsSection from './diagnostics_section.vue';

const warningFinding = {
  severity: 'warning',
  code: 'statement_timeout_unlimited_by_default',
  message:
    'The cluster default for statement_timeout is 0. GitLab sets its own value for each of its sessions, but any other session can run a query with no limit.',
};

const errorFinding = {
  severity: 'error',
  code: 'statement_timeout_unlimited',
  message:
    'statement_timeout is 0 on the connection GitLab uses, so a query can run with no limit.',
};

export default {
  title: 'admin/database_diagnostics/components/diagnostics_section',
  component: DiagnosticsSection,
  parameters: {
    docs: {
      description: {
        component:
          'The shared header, status icon, count badge and finding alerts used by every database diagnostics check. Details start collapsed, so use the Details toggle to reveal the slot content and the finding alerts.',
      },
    },
  },
  argTypes: {
    title: { control: 'text' },
    testidPrefix: {
      control: false,
      description: 'Prefixes the data-testids so each caller stays addressable in its own specs.',
    },
    severity: {
      control: { type: 'select' },
      options: [null, 'warning', 'error', 'info'],
      description:
        'The verdict the check reached. Null renders the success icon; anything unrecognised renders a warning.',
    },
    findings: { control: false },
    count: {
      control: 'number',
      description: 'Replaces the number of findings in the header badge.',
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { DiagnosticsSection },
  template: `
    <diagnostics-section v-bind="$props">
      <p class="gl-mb-0 gl-text-sm gl-text-subtle">
        Slot content: the check renders its own tables and copy here.
      </p>
    </diagnostics-section>
  `,
});

export const Default = Template.bind({});
Default.args = {
  title: 'Timeouts',
  testidPrefix: 'timeouts',
  severity: 'warning',
  findings: [warningFinding],
};

export const NoFindings = Template.bind({});
NoFindings.args = {
  title: 'Timeouts',
  testidPrefix: 'timeouts',
  severity: null,
  findings: [],
};

export const ErrorSeverity = Template.bind({});
ErrorSeverity.args = {
  title: 'Timeouts',
  testidPrefix: 'timeouts',
  severity: 'error',
  findings: [errorFinding, warningFinding],
};

// A severity the frontend does not know about still reports a problem rather
// than a success, so a severity added to the backend stays visible here.
export const UnknownSeverity = Template.bind({});
UnknownSeverity.args = {
  title: 'Timeouts',
  testidPrefix: 'timeouts',
  severity: 'info',
  findings: [warningFinding],
};

// How the search path section renders when the check could read nothing: no
// status icon, no toggle, and no details to fold out.
export const NotFoldable = Template.bind({});
NotFoldable.args = {
  title: 'Timeouts',
  testidPrefix: 'timeouts',
  severity: null,
  findings: [],
  foldable: false,
};

// How the autovacuum settings section uses it: the findings are rendered per
// row by the caller, so only the header badge reports them.
export const FindingAlertsHidden = Template.bind({});
FindingAlertsHidden.args = {
  title: 'Effective settings',
  testidPrefix: 'settings',
  severity: 'warning',
  findings: [warningFinding, warningFinding],
  showFindingAlerts: false,
};

// How the per-table overrides section uses it: the badge counts tables rather
// than findings.
export const CountOverridesFindings = Template.bind({});
CountOverridesFindings.args = {
  title: 'Per-table overrides',
  testidPrefix: 'overrides',
  severity: 'error',
  findings: [],
  count: 12,
};
