const replacer = (fullImport, importName, importPath) => {
  const workerUrl = `${importName}Url`;
  const blobName = `${importName}Blob`;
  return `/* worker import was replaced to support cross-origin workers */
import ${workerUrl} from '${importPath}&url';
const ${blobName} = new Blob([\`import \${JSON.stringify(new URL(${workerUrl}, import.meta.url))}\`], { type: "application/javascript" });
function ${importName}(options) {
  const objURL = URL.createObjectURL(${blobName});
  const worker = new Worker(objURL, { type: "module", name: options?.name });
  worker.addEventListener("error", (e) => { URL.revokeObjectURL(objURL) });
  return worker;
}
/* end of replaced code */`;
};

export const CrossOriginWorkerPlugin = () => {
  let config;
  return {
    name: 'vite-worker-transform-plugin',
    configResolved(resolvedConfig) {
      config = resolvedConfig;
    },
    transform(code) {
      if (config.command !== 'serve' || !code.includes('?worker')) {
        return null;
      }

      return {
        code: code.replace(/import\s+(\w+)\s+from\s+['"](.*?\?worker)['"];/g, replacer),
        map: null,
      };
    },
  };
};
