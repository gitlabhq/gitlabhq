var fs = require('fs'),
  os = require('os'),
  lineReader = require('line-reader');

function help(){
  console.log('Usage: node coffee-asset-pipeline-comments.js file1.coffee');
}

function compilefile(pathname, outdir){
  var src = '';

  lineReader.eachLine(pathname, function(line, last) {
    // asset pipeline comments
    if ( line.indexOf('#') === 0 && line.indexOf('=') === 1) {
      line = line.replace('#', '');
      line = '###' + line + ' ###';
    }
    src += line;
    src += os.EOL;

    if ( last ) {
      fs.writeFile(pathname, src);
    }
  });
}

function main(){
  if (process.argv.length <=2){
    help();
    return;
  }

  console.log('Compiling: '+ process.argv[2]);
  compilefile(process.argv[2]);
}

main();
