const ISSUABLE_REFERENCE_RE = /^((?:[^\s/]+(?:\/(?!#))?)*)#(\d+)$/i;

function getReferencePieces(partialReference, namespacePath, projectPath) {
  const [
    ,
    fullNamespace = '',
    resultantIssue,
  ] = partialReference.match(ISSUABLE_REFERENCE_RE);
  const namespacePieces = fullNamespace.split('/');
  const resultantNamespace = namespacePieces.length > 1 ? namespacePieces.slice(0, -1).join('/') : namespacePath;
  const resultantProject = namespacePieces.slice(-1)[0] || projectPath;

  return {
    namespace: resultantNamespace,
    project: resultantProject,
    issue: resultantIssue,
  };
}

function assembleNecessaryIssuableReference(
  partialReference,
  currentNamespacePath,
  currentProjectPath,
) {
  const {
    namespace,
    project,
    issue,
  } = getReferencePieces(partialReference, currentNamespacePath, currentProjectPath);

  let necessaryReference = `#${issue}`;
  if (currentProjectPath !== project) {
    necessaryReference = project + necessaryReference;
  }
  if (currentNamespacePath !== namespace) {
    necessaryReference = `${namespace}/${necessaryReference}`;
  }

  return necessaryReference;
}

function assembleFullIssuableReference(partialReference, currentNamespacePath, currentProjectPath) {
  const {
    namespace,
    project,
    issue,
  } = getReferencePieces(partialReference, currentNamespacePath, currentProjectPath);
  return `${namespace}/${project}#${issue}`;
}

export {
  ISSUABLE_REFERENCE_RE,
  getReferencePieces,
  assembleNecessaryIssuableReference,
  assembleFullIssuableReference,
};
