<script>
import { GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import DiffFileEditor from './components/diff_file_editor.vue';
import InlineConflictLines from './components/inline_conflict_lines.vue';
import ParallelConflictLines from './components/parallel_conflict_lines.vue';

/**
 * NOTE: Most of this component is directly using $root, rather than props or a better data store.
 * This is BAD and one shouldn't copy that behavior. Similarly a lot of the classes below should
 * be replaced with GitLab UI components.
 *
 * We are just doing it temporarily in order to migrate the template from HAML => Vue in an iterative manner
 * and are going to clean it up as part of:
 *
 * https://gitlab.com/gitlab-org/gitlab/-/issues/321090
 *
 */
export default {
  components: {
    GlSprintf,
    FileIcon,
    DiffFileEditor,
    InlineConflictLines,
    ParallelConflictLines,
  },
  inject: ['mergeRequestPath', 'sourceBranchPath'],
  i18n: {
    commitStatSummary: __('Showing %{conflict} between %{sourceBranch} and %{targetBranch}'),
    resolveInfo: __(
      'You can resolve the merge conflict using either the Interactive mode, by choosing %{use_ours} or %{use_theirs} buttons, or by editing the files directly. Commit these changes into %{branch_name}',
    ),
  },
};
</script>
<template>
  <div id="conflicts">
    <div v-if="$root.isLoading" class="loading">
      <div class="spinner spinner-md"></div>
    </div>
    <div v-if="$root.hasError" class="nothing-here-block">
      {{ $root.conflictsData.errorMessage }}
    </div>
    <template v-if="!$root.isLoading && !$root.hasError">
      <div class="content-block oneline-block files-changed">
        <div v-if="$root.showDiffViewTypeSwitcher" class="inline-parallel-buttons">
          <div class="btn-group">
            <button
              :class="{ active: !$root.isParallel }"
              class="btn gl-button"
              @click="$root.handleViewTypeChange('inline')"
            >
              {{ __('Inline') }}
            </button>
            <button
              :class="{ active: $root.isParallel }"
              class="btn gl-button"
              @click="$root.handleViewTypeChange('parallel')"
            >
              {{ __('Side-by-side') }}
            </button>
          </div>
        </div>
        <div class="js-toggle-container">
          <div class="commit-stat-summary">
            <gl-sprintf :message="$options.i18n.commitStatSummary">
              <template #conflict>
                <strong class="cred">
                  {{ $root.conflictsCountText }}
                </strong>
              </template>
              <template #sourceBranch>
                <strong class="ref-name">
                  {{ $root.conflictsData.sourceBranch }}
                </strong>
              </template>
              <template #targetBranch>
                <strong class="ref-name">
                  {{ $root.conflictsData.targetBranch }}
                </strong>
              </template>
            </gl-sprintf>
          </div>
        </div>
      </div>
      <div class="files-wrapper">
        <div class="files">
          <div
            v-for="file in $root.conflictsData.files"
            :key="file.blobPath"
            class="diff-file file-holder conflict"
          >
            <div class="js-file-title file-title file-title-flex-parent cursor-default">
              <div class="file-header-content">
                <file-icon :file-name="file.filePath" :size="18" css-classes="gl-mr-2" />
                <strong class="file-title-name">{{ file.filePath }}</strong>
              </div>
              <div class="file-actions d-flex align-items-center gl-ml-auto gl-align-self-start">
                <div v-if="file.type === 'text'" class="btn-group gl-mr-3">
                  <button
                    :class="{ active: file.resolveMode === 'interactive' }"
                    class="btn gl-button"
                    type="button"
                    @click="$root.onClickResolveModeButton(file, 'interactive')"
                  >
                    {{ __('Interactive mode') }}
                  </button>
                  <button
                    :class="{ active: file.resolveMode === 'edit' }"
                    class="btn gl-button"
                    type="button"
                    @click="$root.onClickResolveModeButton(file, 'edit')"
                  >
                    {{ __('Edit inline') }}
                  </button>
                </div>
                <a :href="file.blobPath" class="btn gl-button view-file">
                  <gl-sprintf :message="__('View file @ %{commitSha}')">
                    <template #commitSha>
                      {{ $root.conflictsData.shortCommitSha }}
                    </template>
                  </gl-sprintf>
                </a>
              </div>
            </div>
            <div class="diff-content diff-wrap-lines">
              <div
                v-show="
                  !$root.isParallel && file.resolveMode === 'interactive' && file.type === 'text'
                "
                class="file-content"
              >
                <inline-conflict-lines :file="file" />
              </div>
              <div
                v-show="
                  $root.isParallel && file.resolveMode === 'interactive' && file.type === 'text'
                "
                class="file-content"
              >
                <parallel-conflict-lines :file="file" />
              </div>
              <div v-show="file.resolveMode === 'edit' || file.type === 'text-editor'">
                <diff-file-editor
                  :file="file"
                  :on-accept-discard-confirmation="$root.acceptDiscardConfirmation"
                  :on-cancel-discard-confirmation="$root.cancelDiscardConfirmation"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
      <hr />
      <div class="resolve-conflicts-form">
        <div class="form-group row">
          <div class="col-md-4">
            <h4>
              {{ __('Resolve conflicts on source branch') }}
            </h4>
            <div class="resolve-info">
              <gl-sprintf :message="$options.i18n.resolveInfo">
                <template #use_ours>
                  <code>{{ s__('MergeConflict|Use ours') }}</code>
                </template>
                <template #use_theirs>
                  <code>{{ s__('MergeConflict|Use theirs') }}</code>
                </template>
                <template #branch_name>
                  <a class="ref-name" :href="sourceBranchPath">
                    {{ $root.conflictsData.sourceBranch }}
                  </a>
                </template>
              </gl-sprintf>
            </div>
          </div>
          <div class="col-md-8">
            <label class="label-bold" for="commit-message">
              {{ __('Commit message') }}
            </label>
            <div class="commit-message-container">
              <div class="max-width-marker"></div>
              <textarea
                id="commit-message"
                v-model="$root.conflictsData.commitMessage"
                class="form-control js-commit-message"
                rows="5"
              ></textarea>
            </div>
          </div>
        </div>
        <div class="form-group row">
          <div class="offset-md-4 col-md-8">
            <div class="row">
              <div class="col-6">
                <button
                  :disabled="!$root.readyToCommit"
                  class="btn gl-button btn-success js-submit-button"
                  type="button"
                  @click="$root.commit()"
                >
                  <span>{{ $root.commitButtonText }}</span>
                </button>
              </div>
              <div class="col-6 text-right">
                <a :href="mergeRequestPath" class="gl-button btn btn-default">
                  {{ __('Cancel') }}
                </a>
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>
