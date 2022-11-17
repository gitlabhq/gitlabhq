import { describeMarkdownSnapshots } from 'jest/content_editor/markdown_snapshot_spec_helper';

jest.mock('~/emoji');

// See https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#markdown-snapshot-testing
// for documentation on this spec.
//
// NOTE: Unlike the backend markdown_snapshot_spec.rb which has a CE and EE version, there is only
// one version of this spec. This is because the frontend markdown rendering does not require EE-only
// backend features.
describeMarkdownSnapshots('markdown example snapshots in ContentEditor');
