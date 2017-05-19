const glob = require('glob');
const fs = require('fs');
const SVGOptimizer = require('svgo');

// node check_svg.js [failIfUncompressedSVGFound = true | false]
const failFlag = process.argv[2];
const failIfUncompressedSVGFound = failFlag !== undefined ? JSON.parse(failFlag) : true;

const svgo = new SVGOptimizer();
const globPath = 'app/views/shared/icons/*.svg';
const globOptions = { mark: true };

function error(err) {
  console.error(err);
  process.exit(1);
}

function saveOptimization(options) {
  const { filepath, data, originalSize, failIfUncompressed } = options;

  fs.writeFile(filepath, data, (err) => {
    if (err) {
      return error(err);
    }

    const compressedSize = fs.statSync(filepath).size;
    const wasUncompressed = compressedSize < originalSize;
    const compression = (100 - ((compressedSize / originalSize) * 100)).toFixed(2);

    if (failIfUncompressed && wasUncompressed) {
      error(`${filepath} was found to be uncompressed - could be compressed by ${compression}%`);
    } else {
      console.log(`${filepath} was compressed by ${compression}%`);
    }
  });
}

function optimize(filepath) {
  fs.readFile(filepath, 'utf8', (err, data) => {
    if (err) {
      return error(err);
    }

    svgo.optimize(data, (result) => {
      saveOptimization({
        filepath,
        data: result.data,
        originalSize: fs.statSync(filepath).size,
        failIfUncompressed: failIfUncompressedSVGFound,
      });
    });
  });
}

glob(globPath, globOptions, (er, files) => {
  files.forEach(filepath => optimize(filepath));
});
