import { s__, n__ } from '~/locale';

export const title = (state) => {
  if (state.isLoading) {
    return s__('BuildArtifacts|Loading artifacts');
  }

  if (state.hasError) {
    return s__('BuildArtifacts|An error occurred while fetching the artifacts');
  }

  return n__('View exposed artifact', 'View %d exposed artifacts', state.artifacts.length);
};
