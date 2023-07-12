import { __, s__ } from '~/locale';
import { DOCS_URL_IN_EE_DIR } from 'jh_else_ce/lib/utils/url_utility';

export const COMPARE_OPTIONS_INPUT_NAME = 'straight';
export const COMPARE_OPTIONS = [
  { value: false, text: s__('CompareRevisions|Only incoming changes from source') },
  { value: true, text: s__('CompareRevisions|Include changes to target since source was created') },
];

export const I18N = {
  title: s__('CompareRevisions|Compare revisions'),
  subtitle: s__(
    'CompareRevisions|Changes are shown as if the %{boldStart}source%{boldEnd} revision was being merged into the %{boldStart}target%{boldEnd} revision. %{linkStart}Learn more about comparing revisions.%{linkEnd}',
  ),
  source: __('Source'),
  swap: s__('CompareRevisions|Swap'),
  target: __('Target'),
  swapRevisions: s__('CompareRevisions|Swap revisions'),
  compare: s__('CompareRevisions|Compare'),
  optionsLabel: s__('CompareRevisions|Show changes'),
  viewMr: s__('CompareRevisions|View open merge request'),
  openMr: s__('CompareRevisions|Create merge request'),
};

export const COMPARE_REVISIONS_DOCS_URL = `${DOCS_URL_IN_EE_DIR}/user/project/repository/branches/#compare-branches`;
