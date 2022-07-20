import path from 'path';
import { describeMarkdownSnapshots } from 'jest/content_editor/markdown_snapshot_spec_helper';

jest.mock('~/emoji');

const glfmSpecificationDir = path.join(__dirname, '..', '..', '..', 'glfm_specification');

// See https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#markdown-snapshot-testing
// for documentation on this spec.
describeMarkdownSnapshots('CE markdown snapshots in ContentEditor', glfmSpecificationDir);
