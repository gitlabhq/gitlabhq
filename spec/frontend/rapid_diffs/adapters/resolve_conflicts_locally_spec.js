import { resolveConflictsLocallyAdapter } from '~/rapid_diffs/adapters/resolve_conflicts_locally';

const mockShow = jest.fn();
const mockState = {};

jest.mock('~/vue_merge_request_widget/components/mr_widget_how_to_merge_modal.vue', () => ({
  name: 'MrWidgetHowToMergeModal',
  props: {
    isFork: { type: Boolean, default: false },
    sourceBranch: { type: String, default: '' },
    sourceProjectPath: { type: String, default: '' },
    sourceProjectDefaultUrl: { type: String, default: '' },
    reviewingDocsPath: { type: String, default: null },
  },
  created() {
    mockState.props = {
      isFork: this.isFork,
      sourceBranch: this.sourceBranch,
      sourceProjectPath: this.sourceProjectPath,
      sourceProjectDefaultUrl: this.sourceProjectDefaultUrl,
      reviewingDocsPath: this.reviewingDocsPath,
    };
  },
  render(h) {
    return h(
      {
        name: 'GlModalStub',
        methods: { show: mockShow },
        render: (createElement) =>
          createElement('div', { attrs: { 'data-testid': 'how-to-merge-modal' } }),
      },
      { ref: 'modal' },
    );
  },
}));

describe('resolveConflictsLocallyAdapter', () => {
  const appData = {
    isFork: 'true',
    sourceBranch: 'feature',
    sourceProjectPath: 'group/project',
    sourceProjectDefaultUrl: 'https://example.com/group/project.git',
    reviewingDocsPath: '/help',
  };

  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('mounts and opens the how-to-merge modal with parsed props', () => {
    resolveConflictsLocallyAdapter.clicks.resolveConflictsLocally.call({ appData });

    expect(document.querySelector('[data-testid="how-to-merge-modal"]')).not.toBe(null);
    expect(mockState.props).toEqual({
      isFork: true,
      sourceBranch: 'feature',
      sourceProjectPath: 'group/project',
      sourceProjectDefaultUrl: 'https://example.com/group/project.git',
      reviewingDocsPath: '/help',
    });
    expect(mockShow).toHaveBeenCalled();
  });
});
