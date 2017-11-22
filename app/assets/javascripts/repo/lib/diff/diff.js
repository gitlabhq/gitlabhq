import { diffLines } from 'diff';

// export default class DirtyDiffWorker {
//   // eslint-disable-next-line class-methods-use-this
//   compute(model) {
//     console.time('a');
//     const originalContent = model.getOriginalModel().getValue();
//     const newContent = model.getModel().getValue();
//     const changes = diffLines(originalContent, newContent);
//
//     let lineNumber = 1;
//     const a = changes.reduce((acc, change) => {
//       const findOnLine = acc.find(c => c.lineNumber === lineNumber);
//
//       if (findOnLine) {
//         Object.assign(findOnLine, change, {
//           modified: true,
//           endLineNumber: (lineNumber + change.count) - 1,
//         });
//       } else if ('added' in change || 'removed' in change) {
//         acc.push(Object.assign({}, change, {
//           lineNumber,
//           modified: undefined,
//           endLineNumber: (lineNumber + change.count) - 1,
//         }));
//       }
//
//       if (!change.removed) {
//         lineNumber += change.count;
//       }
//
//       return acc;
//     }, []);
//     console.timeEnd('a');
//
//     return a;
//   }
// }
